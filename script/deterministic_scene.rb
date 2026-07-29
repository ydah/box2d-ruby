# frozen_string_literal: true

require "rbconfig"

module DeterministicScene
  SEED = 12_345
  BODY_COUNT = 100
  STEPS = 240
  TIME_STEP = 1.0 / 60

  module_function

  def capture
    random = Random.new(SEED)
    world = Box2D::World.new
    world.create_body(position: [0, -1]) { |body| body.box(20, 1) }
    bodies = BODY_COUNT.times.map do |index|
      column = index % 10
      row = index / 10
      x = column - 4.5 + random.rand(-0.04..0.04)
      y = row + 0.6 + random.rand(0.0..0.04)
      angle = random.rand(-0.03..0.03)
      world.create_body(type: :dynamic, position: [x, y], angle:) do |body|
        body.box(0.4, 0.4, density: 1.0, friction: 0.6)
      end
    end
    STEPS.times { world.step(TIME_STEP) }
    bodies.map { |body| body.position.to_a }
  ensure
    world&.destroy if world&.valid?
  end

  def platform
    cpu = RbConfig::CONFIG.fetch("host_cpu")
    os = RbConfig::CONFIG.fetch("host_os")
    return "#{darwin_cpu(cpu)}-darwin" if os.include?("darwin")
    return "#{linux_cpu(cpu)}-linux" if os.include?("linux")
    return "x64-mingw-ucrt" if os.match?(/mingw|mswin/)

    "#{cpu}-#{os}"
  end

  def snapshot_path
    File.expand_path("../spec/snapshots/100_boxes/#{platform}.json", __dir__)
  end

  def darwin_cpu(cpu)
    cpu.match?(/arm|aarch64/) ? "arm64" : "x86_64"
  end
  private_class_method :darwin_cpu

  def linux_cpu(cpu)
    cpu.match?(/arm|aarch64/) ? "aarch64" : "x86_64"
  end
  private_class_method :linux_cpu
end
