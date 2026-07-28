# frozen_string_literal: true

require "box2d"

world = nil
begin
  world = Box2D::World.new
  world.create_body(position: [0, -1], user_data: :ground) { |body| body.box(10, 1) }
  world.create_body(type: :dynamic, position: [0, 4], user_data: :ball) do |body|
    body.circle(radius: 0.5)
  end

  120.times do
    world.step(1.0 / 60)
    world.events.begin_contacts.each do |contact|
      names = [contact.shape_a.body.user_data, contact.shape_b.body.user_data]
      puts "contact began: #{names.join(" <-> ")}"
    end
  end
ensure
  world&.destroy if world&.valid?
end
