# frozen_string_literal: true

RSpec.describe Box2D::Native do
  it "binds the vendored Box2D version" do
    version = described_class.b2GetVersion

    expect([version[:major], version[:minor], version[:revision]]).to eq([3, 1, 0])
  end

  it "exposes every exported Box2D function" do
    functions = described_class.singleton_methods.grep(/\Ab2/)

    expect(functions.length).to eq(409)
    expect(functions).to include(:b2CreateWorld, :b2World_Step, :b2CreatePolygonShape)
  end

  it "loads generated layouts that agree with FFI" do
    described_class::ABI_LAYOUTS.each do |name, layout|
      struct = described_class.const_get(name)

      expect(struct.size).to eq(layout.fetch(:size)), name
      expect(struct.alignment).to eq(layout.fetch(:alignment)), name
      layout.fetch(:offsets).each do |field, offset|
        expect(struct.offset_of(field)).to eq(offset), "#{name}##{field}"
      end
    end
  end
end
