# frozen_string_literal: true

require "json"
require_relative "../script/deterministic_scene"

RSpec.describe "Box2D simulation behavior" do
  def rebound_apex
    world = Box2D::World.new(gravity: [0, -10])
    world.create_body(position: [0, -0.5]) do |body|
      body.box(10, 0.5, restitution: 1.0, friction: 0.0)
    end
    ball = world.create_body(type: :dynamic, position: [0, 5]) do |body|
      body.circle(radius: 0.5, restitution: 1.0, friction: 0.0)
    end
    bounced = false
    apex = -Float::INFINITY
    previous_velocity = 0.0

    360.times do
      world.step(1.0 / 120)
      velocity = ball.linear_velocity[1]
      bounced = true if !bounced && previous_velocity.negative? && velocity.positive?
      apex = [apex, ball.position[1]].max if bounced
      break if bounced && previous_velocity.positive? && !velocity.positive?

      previous_velocity = velocity
    end
    apex
  ensure
    world&.destroy if world&.valid?
  end

  def incline_displacement(friction, angle)
    tangent = [Math.cos(angle), Math.sin(angle)]
    normal = [-Math.sin(angle), Math.cos(angle)]
    world = Box2D::World.new(gravity: [0, -10])
    world.create_body(angle:) { |body| body.box(50, 0.25, friction:) }
    start = [normal[0] * 0.76, normal[1] * 0.76]
    block = world.create_body(type: :dynamic, position: start, angle:) do |body|
      body.box(0.5, 0.5, friction:)
    end
    240.times { world.step(1.0 / 60) }
    delta = [block.position[0] - start[0], block.position[1] - start[1]]
    delta[0] * tangent[0] + delta[1] * tangent[1]
  ensure
    world&.destroy if world&.valid?
  end

  it "matches the platform snapshot for a fixed-seed 100-body scene" do
    expected = JSON.parse(File.read(DeterministicScene.snapshot_path))
    actual = DeterministicScene.capture

    expect(actual.length).to eq(expected.length)
    actual.zip(expected).each_with_index do |(actual_position, expected_position), index|
      aggregate_failures("body #{index}") do
        expect(actual_position[0]).to be_within(1e-4).of(expected_position[0])
        expect(actual_position[1]).to be_within(1e-4).of(expected_position[1])
      end
    end
  end

  it "returns a restitution-one body to its original drop height" do
    expect(rebound_apex).to be_within(0.05).of(5.0)
  end

  it "respects the static-friction threshold on an incline" do
    angle = 20 * Math::PI / 180
    threshold = Math.tan(angle)
    sliding_friction = 0.2
    holding_friction = 0.5

    expect(sliding_friction).to be < threshold
    expect(holding_friction).to be > threshold
    expect(incline_displacement(sliding_friction, angle).abs).to be > 5.0
    expect(incline_displacement(holding_friction, angle).abs).to be < 0.05
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
