# frozen_string_literal: true

require "box2d"
require "rugl"
require_relative "support/box2d_debug_lines"

world = nil
rugl = nil
at_exit do
  world&.destroy if world&.valid?
  rugl&.destroy unless rugl&.destroyed?
end

world = Box2D::World.new
world.create_body(position: [0, -1]) { |body| body.box(8, 1) }
10.times do |index|
  world.create_body(type: :dynamic, position: [(index % 5) - 2, 1 + index / 5.0]) do |body|
    body.box(0.4, 0.4)
  end
end

rugl = Rugl.create(width: 960, height: 720, title: "Box2D debug draw")
positions = rugl.buffer(data: [], usage: :stream)
colors = rugl.buffer(data: [], usage: :stream)
draw_lines = rugl.command(
  vert: <<~GLSL,
    #version 410 core
    layout(location = 0) in vec2 position;
    layout(location = 1) in vec4 color;
    out vec4 vertexColor;
    void main() {
      gl_Position = vec4(position * vec2(0.1, 0.12) + vec2(0.0, -0.65), 0.0, 1.0);
      vertexColor = color;
    }
  GLSL
  frag: <<~GLSL,
    #version 410 core
    in vec4 vertexColor;
    out vec4 fragColor;
    void main() {
      fragColor = vertexColor;
    }
  GLSL
  attributes: {
    position: {buffer: positions, size: 2},
    color: {buffer: colors, size: 4}
  },
  count: Rugl.prop(:count),
  primitive: :lines,
  line_width: 1.5
)

lines = Box2DDebugLines.new
stepper = Box2D::FixedStepper.new(hz: 60)
previous_time = 0.0
rugl.frame do |context|
  delta_time = context[:time] - previous_time
  previous_time = context[:time]
  stepper.advance(delta_time) { |step| world.step(step) }

  lines.clear
  world.debug_draw(flags: [:shapes, :joints]) { |command| lines << command }
  positions.update(data: lines.positions)
  colors.update(data: lines.colors)

  rugl.clear(color: [0.04, 0.05, 0.08, 1.0])
  draw_lines.call(count: lines.positions.length)
end
