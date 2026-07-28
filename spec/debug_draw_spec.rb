# frozen_string_literal: true

RSpec.describe Box2D::DebugDraw do
  before do
    @world = Box2D::World.new
    @world.create_body do |body|
      body.box(1, 1)
      body.circle(radius: 0.5, center: [3, 0])
    end
  end

  after { @world.destroy if @world.valid? }

  it "converts native callbacks into pattern-matchable commands" do
    commands = []

    @world.debug_draw(flags: [:shapes, :aabbs]) { |command| commands << command }

    expect(commands.map(&:first)).to include(:solid_polygon, :solid_circle, :polygon)
    solid_circle = commands.find { |command| command.first == :solid_circle }
    expect(solid_circle[1]).to include(:position, :angle)
  end

  it "retains callbacks on the world across garbage collection" do
    GC.start
    commands = []

    @world.debug_draw { |command| commands << command }
    GC.start
    @world.debug_draw { |command| commands << command }

    expect(commands).not_to be_empty
  end

  it "reports invalid flags before entering native code" do
    expect { @world.debug_draw(flags: [:unknown]) {} }.to raise_error(ArgumentError, /unknown/)
  end

  it "propagates rendering errors after the native draw returns" do
    expect do
      @world.debug_draw { raise "renderer failed" }
    end.to raise_error("renderer failed")
  end
end
