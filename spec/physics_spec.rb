# frozen_string_literal: true

RSpec.describe "Box2D simulation behavior" do
  def deterministic_snapshot
    world = Box2D::World.new
    world.create_body(position: [0, -1]) { |body| body.box(50, 1) }
    bodies = 100.times.map do |index|
      x = (index % 10) - 5
      y = (index / 10) + 1
      world.create_body(type: :dynamic, position: [x, y]) { |body| body.box(0.4, 0.4) }
    end
    180.times { world.step(1.0 / 60) }
    bodies.flat_map(&:position).map { |value| value.round(6) }
  ensure
    world&.destroy if world&.valid?
  end

  it "is deterministic for a fixed 100-body scene" do
    expect(deterministic_snapshot).to eq(deterministic_snapshot)
  end

  it "emits sensor overlap events" do
    world = Box2D::World.new
    sensor = world.create_body(position: [0, 1]) do |body|
      body.box(2, 0.25, sensor: true)
    end.shapes.first
    visitor = world.create_body(type: :dynamic, position: [0, 4]) do |body|
      body.circle(radius: 0.25)
    end
    event = nil

    120.times do
      world.step(1.0 / 60)
      event ||= world.events.sensor_begins.first
    end

    expect(event.sensor).to eq(sensor)
    expect(event.visitor.body).to eq(visitor)
  ensure
    world&.destroy if world&.valid?
  end
end
