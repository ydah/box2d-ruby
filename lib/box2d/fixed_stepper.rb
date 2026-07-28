# frozen_string_literal: true

module Box2D
  class FixedStepper
    attr_reader :step, :max_substeps

    def initialize(hz: 60, max_substeps: 5)
      frequency = ValueConversion.positive_float(hz, label: "hz")
      @step = 1.0 / frequency
      @max_substeps = Integer(max_substeps)
      raise ArgumentError, "max_substeps must be greater than zero" unless @max_substeps.positive?

      @accumulator = 0.0
    end

    def advance(delta_time)
      raise ArgumentError, "a step block is required" unless block_given?

      delta = ValueConversion.non_negative_float(delta_time, label: "delta_time")
      @accumulator = [@accumulator + delta, @step * @max_substeps].min

      steps = 0
      while @accumulator >= @step && steps < @max_substeps
        yield @step
        @accumulator -= @step
        steps += 1
      end

      @accumulator / @step
    end

    def reset
      @accumulator = 0.0
      self
    end
  end
end
