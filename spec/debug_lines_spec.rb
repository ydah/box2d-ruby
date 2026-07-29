# frozen_string_literal: true

require_relative "../examples/support/box2d_debug_lines"

RSpec.describe Box2DDebugLines do
  it "converts Box2D draw commands to colored line vertices" do
    lines = described_class.new
    lines << [:polygon, [[0, 0], [1, 0], [0, 1]], 0x3366CC]
    lines << [:solid_circle, {position: [2, 3], angle: 0.0}, 0.5, 0xFFFFFF]
    lines << [:segment, [-1, 0], [1, 0], 0xFF0000]

    expect(lines.positions.length).to eq((3 + described_class::CIRCLE_SEGMENTS + 1) * 2)
    expect(lines.colors.length).to eq(lines.positions.length)
    expect(lines.colors.first).to eq([0.2, 0.4, 0.8, 1.0])
  end

  it "applies native transforms and clears accumulated data" do
    lines = described_class.new
    lines << [:solid_polygon, {position: [2, 3], angle: Math::PI / 2}, [[1, 0], [0, 1]], 0.0, 0]

    expect(lines.positions.first[0]).to be_within(1e-12).of(2.0)
    expect(lines.positions.first[1]).to be_within(1e-12).of(4.0)
    expect(lines.clear.positions).to be_empty
    expect(lines.colors).to be_empty
  end
end
