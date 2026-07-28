# frozen_string_literal: true

RSpec.describe Box2D::FixedStepper do
  it "advances using a fixed time step and returns interpolation alpha" do
    stepper = described_class.new(hz: 10, max_substeps: 3)
    steps = []

    alpha = stepper.advance(0.25) { |step| steps << step }

    expect(steps).to contain_exactly(0.1, 0.1)
    expect(alpha).to be_within(1e-12).of(0.5)
  end

  it "caps accumulated time to prevent a spiral of death" do
    stepper = described_class.new(hz: 10, max_substeps: 2)
    count = 0

    alpha = stepper.advance(10) { count += 1 }

    expect(count).to eq(2)
    expect(alpha).to be_within(1e-12).of(0.0)
  end

  it "does not lose an exact step to floating-point rounding" do
    stepper = described_class.new(hz: 10, max_substeps: 3)
    count = 0

    alpha = stepper.advance(0.3) { count += 1 }

    expect(count).to eq(3)
    expect(alpha).to eq(0.0)
  end

  it "rejects invalid configuration and deltas" do
    expect { described_class.new(hz: 0) }.to raise_error(ArgumentError)
    expect { described_class.new(max_substeps: 0) }.to raise_error(ArgumentError)
    expect { described_class.new.advance(-1) {} }.to raise_error(ArgumentError)
  end
end
