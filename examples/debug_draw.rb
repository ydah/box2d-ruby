# frozen_string_literal: true

require "box2d"

world = nil
begin
  world = Box2D::World.new
  world.create_body { |body| body.box(2, 1) }

  world.debug_draw(flags: [:shapes, :aabbs]) do |command|
    p command
  end
ensure
  world&.destroy if world&.valid?
end
