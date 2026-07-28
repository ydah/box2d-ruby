# frozen_string_literal: true

RSpec.describe Box2D::Joint do
  before do
    @world = Box2D::World.new(gravity: [0, 0])
    @ground = @world.create_body
  end

  after { @world.destroy if @world.valid? }

  def dynamic_body(position)
    @world.create_body(type: :dynamic, position:) { |body| body.circle(radius: 0.25) }
  end

  it "creates and controls a revolute joint" do
    body = dynamic_body([2, 0])
    joint = @world.create_revolute_joint(
      body_a: @ground,
      body_b: body,
      anchor: [1, 0],
      limits: (-0.5..0.5),
      motor: {speed: 2, max_torque: 10},
      user_data: :hinge
    )

    joint.motor_speed = -2
    @world.step(1.0 / 60)

    expect(joint).to be_valid
    expect(joint.motor_speed).to eq(-2.0)
    expect(joint.limits).to eq(-0.5..0.5)
    expect(joint.user_data).to eq(:hinge)
  end

  it "creates prismatic, distance, mouse, and weld joints" do
    slider = dynamic_body([1, 1])
    tethered = dynamic_body([2, 1])
    dragged = dynamic_body([3, 1])
    welded = dynamic_body([4, 1])

    prismatic = @world.create_prismatic_joint(
      body_a: @ground,
      body_b: slider,
      anchor: [1, 1],
      limits: (-1.0..1.0),
      motor: {speed: 1, max_force: 10}
    )
    distance = @world.create_distance_joint(
      body_a: @ground,
      body_b: tethered,
      anchor_a: [0, 0],
      anchor_b: [2, 1],
      spring: {hertz: 2}
    )
    mouse = @world.create_mouse_joint(
      body_a: @ground,
      body_b: dragged,
      target: [3, 1],
      max_force: 100
    )
    weld = @world.create_weld_joint(body_a: @ground, body_b: welded, anchor: [4, 1])

    expect(prismatic.translation).to be_within(1e-5).of(0)
    expect(distance.length).to be_within(1e-5).of(Math.sqrt(5))
    expect(mouse.target).to eq([3.0, 1.0])
    expect(weld.reference_angle).to eq(0.0)
  end

  it "invalidates a joint when either connected body is destroyed" do
    body = dynamic_body([2, 0])
    joint = @world.create_revolute_joint(body_a: @ground, body_b: body, anchor: [1, 0])

    body.destroy

    expect(joint).not_to be_valid
    expect { joint.angle }.to raise_error(Box2D::UseAfterDestroyError)
  end

  it "validates body ownership and joint limits" do
    body = dynamic_body([2, 0])
    other_world = Box2D::World.new
    other_body = other_world.create_body(type: :dynamic)

    expect do
      @world.create_revolute_joint(body_a: @ground, body_b: other_body, anchor: [0, 0])
    end.to raise_error(ArgumentError, /belong/)
    expect do
      @world.create_revolute_joint(body_a: @ground, body_b: body, anchor: [0, 0], limits: (2..-2))
    end.to raise_error(ArgumentError, /lower limit/)
  ensure
    other_world&.destroy if other_world&.valid?
  end
end
