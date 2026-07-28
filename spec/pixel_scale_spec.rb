# frozen_string_literal: true

RSpec.describe Box2D::PixelScale do
  subject(:scale) { described_class.new(64) }

  it "converts scalar and vector units" do
    expect(scale.to_pixels(1.5)).to eq(96.0)
    expect(scale.to_meters(32)).to eq(0.5)
    expect(scale.vector_to_pixels([1, -2])).to eq([64.0, -128.0])
    expect(scale.vector_to_meters([32, 96])).to eq([0.5, 1.5])
  end

  it "rejects a non-positive scale" do
    expect { described_class.new(0) }.to raise_error(ArgumentError)
  end
end
