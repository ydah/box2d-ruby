# frozen_string_literal: true

RSpec.describe "native lifetime under GC pressure" do
  it "survives 1000 steps with creation, destruction, events, and draw callbacks" do
    world = Box2D::World.new
    world.create_body(position: [0, -1]) { |body| body.box(10, 1) }
    world.create_body(type: :dynamic, position: [0, 4]) { |body| body.circle(radius: 0.5) }
    previous_stress = GC.stress

    begin
      GC.stress = true
      1000.times do |index|
        if (index % 100).zero?
          transient = world.create_body(type: :dynamic, position: [5, 5]) { |body| body.circle(radius: 0.1) }
          transient.destroy
          world.debug_draw(flags: [:shapes]) { |_command| nil }
        end
        world.step(1.0 / 60)
      end
    ensure
      GC.stress = previous_stress
      world.destroy if world.valid?
    end

    expect(world).not_to be_valid
  end
end
