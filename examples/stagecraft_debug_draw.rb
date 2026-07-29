# frozen_string_literal: true

require "box2d"
require "stagecraft"
require_relative "support/box2d_debug_lines"

world = nil
app = nil
begin
world = Box2D::World.new
world.create_body(position: [0, -1]) { |body| body.box(8, 1) }
10.times do |index|
  world.create_body(type: :dynamic, position: [(index % 5) - 2, 1 + index / 5.0]) do |body|
    body.circle(radius: 0.4)
  end
end

app = Stagecraft::App.new(title: "Box2D debug draw", width: 960, height: 720)
scene = Stagecraft::Scene.new
scene.background = "#0a0d14"
camera = Stagecraft::Cameras::Orthographic.new(
  left: -10, right: 10, top: 12, bottom: -3, near: 0.1, far: 20
)
camera.position.z = 10

geometry = Stagecraft::Geometry.new(topology: :line_list)
geometry.set_attribute(:position, data: "".b, format: :float32x3, count: 0)
geometry.set_attribute(:color, data: "".b, format: :float32x4, count: 0)
mesh = Stagecraft::Mesh.new(geometry, Stagecraft::Materials::Unlit.new)
mesh.frustum_culled = false
scene.add(mesh)

lines = Box2DDebugLines.new
stepper = Box2D::FixedStepper.new(hz: 60)
app.run do |delta_time|
  stepper.advance(delta_time) { |step| world.step(step) }
  lines.clear
  world.debug_draw(flags: [:shapes, :joints]) { |command| lines << command }

  next_geometry = Stagecraft::Geometry.new(topology: :line_list)
  next_geometry.set_attribute(
    :position,
    data: lines.positions.flat_map { |x, y| [x, y, 0.0] }.pack("e*"),
    format: :float32x3,
    count: lines.positions.length
  )
  next_geometry.set_attribute(
    :color,
    data: lines.colors.flatten.pack("e*"),
    format: :float32x4,
    count: lines.colors.length
  )
  mesh.geometry = next_geometry
  geometry.dispose
  geometry = next_geometry
  app.renderer.render(scene, camera)
end
ensure
  world&.destroy if world&.valid?
  if app && !app.renderer.disposed?
    app.renderer.dispose
    app.window.close
  end
end
