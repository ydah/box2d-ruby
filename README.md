# box2d-ruby

`box2d-ruby` is an idiomatic Ruby binding for the Box2D 3 C API. It ships a
complete generated FFI layer and a memory-safe Ruby API for worlds, bodies,
shapes, events, queries, joints, and debug drawing.

The gem currently vendors Box2D 3.1.0.

## Units and coordinates

Box2D uses SI units: meters, kilograms, seconds, and radians. It has no built-in
pixel scale and this binding uses a y-up coordinate system.

Do not pass screen pixels directly to physics APIs. A common game scale is
32–64 pixels per meter:

```ruby
scale = Box2D::PixelScale.new(64)
physics_position = scale.vector_to_meters([320, 128])
screen_position = scale.vector_to_pixels(physics_position)
```

## Installation

Add the gem to your bundle:

```sh
bundle add box2d-ruby
```

Or install it directly:

```sh
gem install box2d-ruby
```

Platform gems contain a precompiled Box2D library. The source gem falls back to
building the vendored C17 source and requires a C compiler, `make`, and Ruby
development headers.

The runtime dependency is `ffi`. `larb` is optional: if it is already loaded,
vector-returning APIs produce `Larb::Vec2`; otherwise they return two-element
arrays.

## Quick start

```ruby
require "box2d"

world = Box2D::World.new(gravity: [0, -9.8]) do |configuration|
  configuration.substeps = 4
end

world.create_body(type: :static, position: [0, -10]) do |body|
  body.box(50, 10)
end

ball = world.create_body(
  type: :dynamic,
  position: [0, 4],
  user_data: {kind: :ball}
) do |body|
  body.circle(
    radius: 0.5,
    density: 1.0,
    friction: 0.3,
    restitution: 0.6
  )
  body.bullet = true
end

60.times { world.step(1.0 / 60) }

p ball.position
ball.linear_velocity = [3, 0]
ball.apply_impulse([0, 5])

world.destroy
```

`World#step` releases Ruby's GVL while Box2D is solving. Accessing the same
world from another Ruby thread during a step is rejected with
`Box2D::ReentrantStepError`.

## Fixed timestep

`FixedStepper` implements an accumulator with a substep cap:

```ruby
stepper = Box2D::FixedStepper.new(hz: 60, max_substeps: 5)

app.run do |delta_time|
  alpha = stepper.advance(delta_time) { |step| world.step(step) }
  render(alpha)
end
```

`advance` returns interpolation alpha in `[0, 1)`. Excess accumulated time is
discarded at `max_substeps` to prevent a spiral of death.

## Shapes

A body block is a shape builder:

```ruby
body = world.create_body(type: :dynamic, position: [0, 3]) do |builder|
  builder.box(half_width, half_height, center: [0, 0], angle: 0)
  builder.circle(radius: 0.5, center: [0, 0])
  builder.capsule([-1, 0], [1, 0], radius: 0.25)
  builder.polygon([[0, 0], [1, 0], [0, 1]])
  builder.segment([-1, 0], [1, 0])
end
```

Every shape builder accepts:

- `density`, `friction`, `restitution`, and `rolling_resistance`
- `sensor: true`
- `filter: {category:, mask:, group:}`
- `sensor_events`, `contact_events`, and `hit_events`
- Ruby-owned `user_data`

Chains are separate native objects:

```ruby
chain = ground.chain(
  [[-4, 0], [-2, 1], [2, 1], [4, 0]],
  loop: false,
  friction: 0.8
)
```

Box2D chains require at least four vertices.

## Events

Contact and sensor event buffers are transient in Box2D. `World#step` copies
them into immutable Ruby values before returning:

```ruby
world.step(1.0 / 60)

world.events.begin_contacts.each do |contact|
  a = contact.shape_a.body.user_data
  b = contact.shape_b.body.user_data
  p [a, b, contact.manifold]
end

world.events.end_contacts.each { |contact| p contact }
world.events.hits.each { |hit| p hit.approach_speed }
world.events.sensor_begins.each { |event| p [event.sensor, event.visitor] }
world.events.sensor_ends.each { |event| p [event.sensor, event.visitor] }
```

## Queries

```ruby
hit = world.raycast([0, 10], [0, -10])
if hit
  p [hit.shape, hit.point, hit.normal, hit.fraction]
end

world.overlap_aabb([-2, -2], [2, 2]) do |shape|
  p shape
end
```

Both methods accept `filter: {category:, mask:}`.

## Joints

The high-level API supports revolute, prismatic, distance, mouse, and weld
joints:

```ruby
joint = world.create_revolute_joint(
  body_a: arm,
  body_b: hand,
  anchor: [1, 2],
  limits: (-0.5..0.5),
  motor: {speed: 2.0, max_torque: 10.0}
)

joint.motor_speed = -2.0
joint.destroy
```

Equivalent constructors are:

- `create_prismatic_joint`
- `create_distance_joint`
- `create_mouse_joint`
- `create_weld_joint`

All anchors supplied to constructors are world coordinates and are converted to
body-local coordinates internally.

## Debug drawing

Debug drawing converts native callbacks into arrays suitable for Ruby pattern
matching:

```ruby
world.debug_draw(flags: [:shapes, :joints, :aabbs]) do |command|
  case command
  in [:polygon, points, color]
    draw_outline(points, color)
  in [:solid_circle, transform, radius, color]
    draw_circle(transform[:position], radius, color)
  in [:segment, point1, point2, color]
    draw_line(point1, point2, color)
  else
    # Other commands include solid_polygon, solid_capsule, transform,
    # point, circle, and string.
  end
end
```

The owning world retains every `FFI::Function` used by the draw session, so GC
cannot collect a callback while native code is using it.

## Ownership and destruction

`World` owns every native body, shape, chain, and joint. Ruby wrappers are
non-owning ID values and do not use GC finalizers.

Destroy resources explicitly:

```ruby
shape.destroy
body.destroy
joint.destroy
world.destroy # destroys all remaining children
```

Access through a destroyed handle raises `Box2D::UseAfterDestroyError`. Ruby
objects assigned as `user_data` are held in world-side registries; Ruby object
pointers are never written to Box2D's native `void*` fields.

## Native API

All 409 exported Box2D 3.1.0 functions are available under `Box2D::Native`.
Structs, enums, and function signatures are generated from the vendored headers:

```ruby
version = Box2D::Native.b2GetVersion
p [version[:major], version[:minor], version[:revision]]
```

Set `BOX2D_LIBRARY_PATH` to load a compatible external Box2D shared library
instead of the bundled extension.

## Development

Install dependencies and run the complete quality gate:

```sh
bundle install
bundle exec rake
```

The default task:

1. builds the vendored native library;
2. checks that generated FFI declarations match the headers;
3. compiles a C layout probe and checks all 71 struct sizes, alignments, and
   field offsets;
4. runs the RSpec suite, including 1000 steps under `GC.stress`.

Useful tasks:

```sh
bundle exec rake bindings:generate
bundle exec rake bindings:check
bundle exec rake native:compile
bundle exec rake native:package
bundle exec rake build
```

See `examples/` for complete runnable scripts.

## License

The Ruby binding is available under the MIT License. Vendored Box2D source is
also MIT licensed; its license is included at
`ext/box2d/vendor/box2d/LICENSE`.
