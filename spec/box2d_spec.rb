# frozen_string_literal: true

RSpec.describe Box2D do
  it "has a version number" do
    expect(described_class::VERSION).to eq("1.0.0")
  end

  it "keeps the generated gem namespace compatible with the original skeleton" do
    expect(Box2d).to equal(described_class)
  end
end
