# frozen_string_literal: true

require "box2d"

world = nil
begin
  world = Box2D::World.new
  world.create_body(position: [0, -1]) { |body| body.box(10, 1) }
  ball = world.create_body(type: :dynamic, position: [0, 4]) do |body|
    body.circle(radius: 0.5, restitution: 0.6)
  end

  120.times do |frame|
    world.step(1.0 / 60)
    puts format("%3d: x=% .3f y=% .3f", frame, *ball.position)
  end
ensure
  world&.destroy if world&.valid?
end
