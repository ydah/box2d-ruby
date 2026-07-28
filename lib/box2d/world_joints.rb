# frozen_string_literal: true

module Box2D
  module WorldJoints
    def create_revolute_joint(body_a:, body_b:, anchor:, limits: nil, motor: nil, spring: nil, **options)
      create_typed_joint(:revolute, body_a:, body_b:, options:) do |definition|
        definition[:localAnchorA] = local_point(body_a, anchor)
        definition[:localAnchorB] = local_point(body_b, anchor)
        definition[:referenceAngle] = body_b.angle - body_a.angle
        configure_limits(definition, limits, :lowerAngle, :upperAngle)
        configure_motor(definition, motor, maximum: :maxMotorTorque)
        configure_spring(definition, spring)
      end
    end

    def create_prismatic_joint(body_a:, body_b:, anchor:, axis: [1, 0], limits: nil, motor: nil, spring: nil, **options)
      create_typed_joint(:prismatic, body_a:, body_b:, options:) do |definition|
        definition[:localAnchorA] = local_point(body_a, anchor)
        definition[:localAnchorB] = local_point(body_b, anchor)
        definition[:localAxisA] = Native.b2Body_GetLocalVector(
          body_a.id,
          ValueConversion.native_vec2(axis, label: "axis")
        )
        definition[:referenceAngle] = body_b.angle - body_a.angle
        configure_limits(definition, limits, :lowerTranslation, :upperTranslation)
        configure_motor(definition, motor, maximum: :maxMotorForce)
        configure_spring(definition, spring)
      end
    end

    def create_distance_joint(body_a:, body_b:, anchor_a: nil, anchor_b: nil, length: nil, limits: nil,
      motor: nil, spring: nil, **options)
      point_a = anchor_a || body_a.position
      point_b = anchor_b || body_b.position
      create_typed_joint(:distance, body_a:, body_b:, options:) do |definition|
        definition[:localAnchorA] = local_point(body_a, point_a)
        definition[:localAnchorB] = local_point(body_b, point_b)
        definition[:length] = length ? ValueConversion.positive_float(length, label: "length") : distance(point_a, point_b)
        configure_limits(definition, limits, :minLength, :maxLength)
        configure_motor(definition, motor, maximum: :maxMotorForce)
        configure_spring(definition, spring)
      end
    end

    def create_mouse_joint(body_a:, body_b:, target:, max_force:, hertz: 5.0, damping_ratio: 0.7, **options)
      create_typed_joint(:mouse, body_a:, body_b:, options:) do |definition|
        definition[:target] = ValueConversion.native_vec2(target, label: "target")
        definition[:maxForce] = ValueConversion.positive_float(max_force, label: "max_force")
        definition[:hertz] = ValueConversion.non_negative_float(hertz, label: "hertz")
        definition[:dampingRatio] = ValueConversion.non_negative_float(damping_ratio, label: "damping_ratio")
      end
    end

    def create_weld_joint(body_a:, body_b:, anchor:, linear: nil, angular: nil, **options)
      create_typed_joint(:weld, body_a:, body_b:, options:) do |definition|
        definition[:localAnchorA] = local_point(body_a, anchor)
        definition[:localAnchorB] = local_point(body_b, anchor)
        definition[:referenceAngle] = body_b.angle - body_a.angle
        configure_weld_spring(definition, linear, :linear)
        configure_weld_spring(definition, angular, :angular)
      end
    end

    private

    JOINT_TYPES = {
      revolute: [Native.method(:b2DefaultRevoluteJointDef), Native.method(:b2CreateRevoluteJoint), RevoluteJoint],
      prismatic: [Native.method(:b2DefaultPrismaticJointDef), Native.method(:b2CreatePrismaticJoint), PrismaticJoint],
      distance: [Native.method(:b2DefaultDistanceJointDef), Native.method(:b2CreateDistanceJoint), DistanceJoint],
      mouse: [Native.method(:b2DefaultMouseJointDef), Native.method(:b2CreateMouseJoint), MouseJoint],
      weld: [Native.method(:b2DefaultWeldJointDef), Native.method(:b2CreateWeldJoint), WeldJoint]
    }.freeze

    def create_typed_joint(type, body_a:, body_b:, options:)
      ensure_access!
      validate_joint_bodies(body_a, body_b)
      default_function, create_function, wrapper_class = JOINT_TYPES.fetch(type)
      definition = default_function.call
      definition[:bodyIdA] = body_a.id
      definition[:bodyIdB] = body_b.id
      definition[:collideConnected] = !!options.fetch(:collide_connected, false)
      yield definition

      joint = wrapper_class.new(
        self,
        create_function.call(@id, definition.pointer),
        body_a:,
        body_b:,
        user_data: options[:user_data]
      )
      body_a.register_joint(joint)
      body_b.register_joint(joint)
      register_joint(joint)
    end

    def validate_joint_bodies(body_a, body_b)
      raise ArgumentError, "joint bodies must be distinct" if body_a.equal?(body_b)
      raise ArgumentError, "joint bodies must belong to this world" unless body_a.world.equal?(self) && body_b.world.equal?(self)
      raise UseAfterDestroyError, "joint body has been destroyed" unless body_a.valid? && body_b.valid?
    end

    def local_point(body, point)
      Native.b2Body_GetLocalPoint(body.id, ValueConversion.native_vec2(point, label: "anchor"))
    end

    def configure_limits(definition, limits, lower_field, upper_field)
      return unless limits

      lower = ValueConversion.finite_float(limits.begin, label: "lower_limit")
      upper = ValueConversion.finite_float(limits.end, label: "upper_limit")
      raise ArgumentError, "lower limit must not exceed upper limit" if lower > upper

      definition[:enableLimit] = true
      definition[lower_field] = lower
      definition[upper_field] = upper
    end

    def configure_motor(definition, motor, maximum:)
      return unless motor

      definition[:enableMotor] = true
      definition[:motorSpeed] = ValueConversion.finite_float(motor.fetch(:speed, 0), label: "motor.speed")
      definition[maximum] = ValueConversion.non_negative_float(
        motor.fetch(maximum == :maxMotorTorque ? :max_torque : :max_force),
        label: "motor maximum"
      )
    end

    def configure_spring(definition, spring)
      return unless spring

      definition[:enableSpring] = true
      definition[:hertz] = ValueConversion.non_negative_float(spring.fetch(:hertz), label: "spring.hertz")
      definition[:dampingRatio] = ValueConversion.non_negative_float(
        spring.fetch(:damping_ratio, 0.7),
        label: "spring.damping_ratio"
      )
    end

    def configure_weld_spring(definition, spring, prefix)
      return unless spring

      definition[:"#{prefix}Hertz"] = ValueConversion.non_negative_float(spring.fetch(:hertz), label: "#{prefix}.hertz")
      definition[:"#{prefix}DampingRatio"] = ValueConversion.non_negative_float(
        spring.fetch(:damping_ratio, 0.7),
        label: "#{prefix}.damping_ratio"
      )
    end

    def distance(point_a, point_b)
      vector_a = ValueConversion.native_vec2(point_a, label: "anchor_a")
      vector_b = ValueConversion.native_vec2(point_b, label: "anchor_b")
      Math.hypot(vector_b[:x] - vector_a[:x], vector_b[:y] - vector_a[:y])
    end
  end
end
