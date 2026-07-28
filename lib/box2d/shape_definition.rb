# frozen_string_literal: true

module Box2D
  module ShapeDefinition
    module_function

    def build(options)
      definition = Native.b2DefaultShapeDef
      material = definition[:material]
      material[:friction] = ValueConversion.non_negative_float(options.fetch(:friction, 0.6), label: "friction")
      material[:restitution] = coefficient(options.fetch(:restitution, 0.0), "restitution")
      material[:rollingResistance] = coefficient(options.fetch(:rolling_resistance, 0.0), "rolling_resistance")
      material[:tangentSpeed] = ValueConversion.finite_float(options.fetch(:tangent_speed, 0.0), label: "tangent_speed")
      material[:userMaterialId] = Integer(options.fetch(:material, 0))
      definition[:density] = ValueConversion.non_negative_float(options.fetch(:density, 1.0), label: "density")
      definition[:isSensor] = !!options.fetch(:sensor, false)
      definition[:enableSensorEvents] = !!options.fetch(:sensor_events, true)
      definition[:enableContactEvents] = !!options.fetch(:contact_events, true)
      definition[:enableHitEvents] = !!options.fetch(:hit_events, true)
      apply_filter(definition[:filter], options.fetch(:filter, {}))
      definition
    end

    def query_filter(options)
      filter = Native.b2DefaultQueryFilter
      filter[:categoryBits] = Integer(options.fetch(:category, filter[:categoryBits]))
      filter[:maskBits] = Integer(options.fetch(:mask, filter[:maskBits]))
      filter
    end

    def apply_filter(filter, options)
      filter[:categoryBits] = Integer(options.fetch(:category, filter[:categoryBits]))
      filter[:maskBits] = Integer(options.fetch(:mask, filter[:maskBits]))
      filter[:groupIndex] = Integer(options.fetch(:group, filter[:groupIndex]))
    end

    def coefficient(value, label)
      number = ValueConversion.non_negative_float(value, label:)
      return number if number <= 1.0

      raise ArgumentError, "#{label} must be between 0 and 1"
    end
  end
end
