# frozen_string_literal: true

module Box2D
  module ValueConversion
    module_function

    def native_vec2(value, label: "vector")
      x, y = pair(value, label:)
      Native::Vec2.new.tap do |vector|
        vector[:x] = finite_float(x, label: "#{label}.x")
        vector[:y] = finite_float(y, label: "#{label}.y")
      end
    end

    def native_rot(angle)
      radians = finite_float(angle, label: "angle")
      Native::Rot.new.tap do |rotation|
        rotation[:c] = Math.cos(radians)
        rotation[:s] = Math.sin(radians)
      end
    end

    def vec2(value)
      x = value[:x]
      y = value[:y]
      return Larb::Vec2.new(x, y) if defined?(Larb::Vec2)

      [x, y]
    end

    def finite_float(value, label:)
      number = Float(value)
      return number if number.finite?

      raise ArgumentError, "#{label} must be finite"
    rescue TypeError, ArgumentError
      raise ArgumentError, "#{label} must be a finite number"
    end

    def positive_float(value, label:)
      number = finite_float(value, label:)
      return number if number.positive?

      raise ArgumentError, "#{label} must be greater than zero"
    end

    def non_negative_float(value, label:)
      number = finite_float(value, label:)
      return number if number >= 0.0

      raise ArgumentError, "#{label} must be non-negative"
    end

    def copy_struct(struct_class, value)
      struct_class.new.tap do |copy|
        copy.pointer.put_bytes(0, value.pointer.read_bytes(struct_class.size))
      end
    end

    def id_key(id)
      members = id.class.members
      key = Integer(id[:index1]) | (Integer(id[:generation]) << 32)
      return key unless members.include?(:world0)

      key | (Integer(id[:world0]) << 48)
    end

    def pair(value, label:)
      pair = if value.respond_to?(:to_ary)
        value.to_ary
      elsif value.respond_to?(:x) && value.respond_to?(:y)
        [value.x, value.y]
      end
      return pair if pair&.length == 2

      raise ArgumentError, "#{label} must contain exactly two components"
    end
    private_class_method :pair
  end
end
