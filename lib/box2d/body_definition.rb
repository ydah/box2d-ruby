# frozen_string_literal: true

module Box2D
  module BodyDefinition
    private

    def build_body_definition(type:, position:, angle:, options:)
      definition = Native.b2DefaultBodyDef
      definition[:type] = self.class::BODY_TYPES.fetch(type) do
        raise ArgumentError, "invalid body type: #{type.inspect}"
      end
      definition[:position] = ValueConversion.native_vec2(position, label: "position")
      definition[:rotation] = ValueConversion.native_rot(angle)
      definition[:linearVelocity] = ValueConversion.native_vec2(
        options.fetch(:linear_velocity, [0, 0]),
        label: "linear_velocity"
      )
      definition[:angularVelocity] = ValueConversion.finite_float(
        options.fetch(:angular_velocity, 0),
        label: "angular_velocity"
      )
      definition[:linearDamping] = ValueConversion.non_negative_float(
        options.fetch(:linear_damping, 0),
        label: "linear_damping"
      )
      definition[:angularDamping] = ValueConversion.non_negative_float(
        options.fetch(:angular_damping, 0),
        label: "angular_damping"
      )
      definition[:gravityScale] = ValueConversion.finite_float(options.fetch(:gravity_scale, 1), label: "gravity_scale")
      definition[:isBullet] = !!options.fetch(:bullet, false)
      definition[:fixedRotation] = !!options.fetch(:fixed_rotation, false)
      definition[:isAwake] = !!options.fetch(:awake, true)
      definition[:enableSleep] = !!options.fetch(:sleep, true)
      definition
    end
  end
end
