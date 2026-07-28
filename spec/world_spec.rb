# frozen_string_literal: true

RSpec.describe Box2D::World do
  def create_world(**options)
    described_class.new(**options).tap { |world| @worlds << world }
  end

  before { @worlds = [] }

  after do
    @worlds.each { |world| world.destroy if world.valid? }
  end

  it "simulates dynamic bodies with SI units" do
    world = create_world(gravity: [0, -10])
    body = world.create_body(type: :dynamic, position: [0, 10]) do |builder|
      builder.circle(radius: 0.5)
    end

    60.times { world.step(1.0 / 60) }

    expect(body.linear_velocity[1]).to be_within(0.05).of(-10.0)
    expect(body.position[1]).to be_within(0.15).of(5.0)
  end

  it "builds all core shape types" do
    world = create_world
    body = world.create_body(type: :dynamic) do |builder|
      builder.box(1, 2)
      builder.circle(radius: 0.5)
      builder.capsule([-1, 0], [1, 0], radius: 0.25)
      builder.polygon([[0, 0], [1, 0], [0, 1]])
      builder.segment([-1, 0], [1, 0])
    end

    expect(body.shapes.map(&:type)).to contain_exactly(:polygon, :circle, :capsule, :polygon, :segment)
    expect(body.mass).to be_positive
  end

  it "builds open and looped chains" do
    world = create_world
    body = world.create_body
    chain = body.chain([[-2, 0], [-1, 0], [1, 0], [2, 0]])

    expect(chain).to be_valid
    expect(chain.segments.length).to eq(1)
  end

  it "supports body state, impulses, and Ruby-owned user data" do
    world = create_world(gravity: [0, 0])
    payload = {kind: :player}
    body = world.create_body(type: :dynamic, user_data: payload) do |builder|
      builder.circle(radius: 1, user_data: :main_shape)
    end

    body.linear_velocity = [2, 3]
    body.angular_velocity = 1.5
    body.bullet = true
    body.apply_impulse([4, 0])

    expect(body.linear_velocity[0]).to be > 2
    expect(body.angular_velocity).to eq(1.5)
    expect(body).to be_bullet
    expect(body.user_data).to equal(payload)
    expect(body.shapes.first.user_data).to eq(:main_shape)
  end

  it "captures contact events before native buffers expire" do
    world = create_world
    world.create_body(position: [0, -1]) { |body| body.box(10, 1) }
    ball = world.create_body(type: :dynamic, position: [0, 2]) { |body| body.circle(radius: 0.5) }
    contact = nil

    120.times do
      world.step(1.0 / 60)
      contact ||= world.events.begin_contacts.first
    end

    expect(contact).not_to be_nil
    expect([contact.shape_a.body, contact.shape_b.body]).to include(ball)
    expect(contact.manifold.points).not_to be_empty
  end

  it "performs closest ray casts and AABB overlap queries" do
    world = create_world
    body = world.create_body { |builder| builder.box(1, 1) }

    hit = world.raycast([0, 5], [0, -5])
    overlaps = world.overlap_aabb([-2, -2], [2, 2]).to_a

    expect(hit.shape.body).to eq(body)
    expect(hit.fraction).to be_between(0.0, 1.0)
    expect(overlaps.map(&:body)).to include(body)
  end

  it "invalidates child handles when their owner is destroyed" do
    world = create_world
    body = world.create_body { |builder| builder.box(1, 1) }
    shape = body.shapes.first

    body.destroy

    expect(body).not_to be_valid
    expect(shape).not_to be_valid
    expect { body.position }.to raise_error(Box2D::UseAfterDestroyError)
    expect { shape.friction }.to raise_error(Box2D::UseAfterDestroyError)
  end

  it "destroys an entire world explicitly and idempotently" do
    world = create_world
    body = world.create_body

    expect(world.destroy).to be(true)
    expect(world.destroy).to be(false)
    expect(body).not_to be_valid
    expect { world.step(0.1) }.to raise_error(Box2D::UseAfterDestroyError)
  end

  it "rejects access while a blocking step is in progress" do
    world = create_world
    original = Box2D::Native.method(:b2World_Step)

    allow(Box2D::Native).to receive(:b2World_Step) do
      expect { world.gravity }.to raise_error(Box2D::ReentrantStepError)
    end
    world.step(0.01)
  ensure
    allow(Box2D::Native).to receive(:b2World_Step, &original)
  end

  it "cleans up a partially built body when its block raises" do
    world = create_world

    expect do
      world.create_body(type: :dynamic) do |body|
        body.circle(radius: 1)
        raise "builder failed"
      end
    end.to raise_error("builder failed")

    counters = Box2D::Native.b2World_GetCounters(world.id)
    expect(counters[:bodyCount]).to eq(0)
  end

  it "validates public input at the Ruby boundary" do
    world = create_world

    expect { world.create_body(type: :ghost) }.to raise_error(ArgumentError, /body type/)
    expect { world.create_body(position: [0]) }.to raise_error(ArgumentError, /two components/)
    expect { world.substeps = 0 }.to raise_error(ArgumentError, /substeps/)
    expect { world.step(Float::NAN) }.to raise_error(ArgumentError, /finite/)
    expect do
      world.create_body { |body| body.segment([0, 0], [0, 0]) }
    end.to raise_error(ArgumentError, /segment endpoints/)
    expect { world.overlap_aabb([1, 1], [-1, -1]) {} }.to raise_error(ArgumentError, /AABB/)
  end
end
