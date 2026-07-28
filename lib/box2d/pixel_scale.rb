# frozen_string_literal: true

module Box2D
  class PixelScale
    attr_reader :pixels_per_meter

    def initialize(pixels_per_meter = 32)
      @pixels_per_meter = ValueConversion.positive_float(pixels_per_meter, label: "pixels_per_meter")
    end

    def to_pixels(meters)
      ValueConversion.finite_float(meters, label: "meters") * @pixels_per_meter
    end

    def to_meters(pixels)
      ValueConversion.finite_float(pixels, label: "pixels") / @pixels_per_meter
    end

    def vector_to_pixels(vector)
      x, y = vector
      [to_pixels(x), to_pixels(y)]
    end

    def vector_to_meters(vector)
      x, y = vector
      [to_meters(x), to_meters(y)]
    end
  end
end
