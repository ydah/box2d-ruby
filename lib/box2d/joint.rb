# frozen_string_literal: true

module Box2D
  class Joint < Handle
    ID_CLASS = Native::JointId

    attr_reader :body_a, :body_b
    attr_accessor :user_data

    def initialize(world, id, body_a:, body_b:, user_data: nil)
      super(world, id)
      @body_a = body_a
      @body_b = body_b
      @user_data = user_data
    end

    def destroy
      ensure_valid!
      Native.b2DestroyJoint(@id)
      invalidate_and_unregister
      true
    end

    def collide_connected?
      ensure_valid!
      Native.b2Joint_GetCollideConnected(@id)
    end

    def collide_connected=(value)
      ensure_valid!
      Native.b2Joint_SetCollideConnected(@id, !!value)
    end

    def constraint_force
      ensure_valid!
      ValueConversion.vec2(Native.b2Joint_GetConstraintForce(@id))
    end

    def constraint_torque
      ensure_valid!
      Native.b2Joint_GetConstraintTorque(@id)
    end

    def invalidate_from_body!
      invalidate_and_unregister
    end

    protected

    def native_valid?
      Native.b2Joint_IsValid(@id)
    end

    private

    def invalidate_and_unregister
      invalidate!
      @world.unregister_joint(self)
      @body_a.unregister_joint(self)
      @body_b.unregister_joint(self)
    end
  end

  class RevoluteJoint < Joint
    def angle
      ensure_valid!
      Native.b2RevoluteJoint_GetAngle(@id)
    end

    def motor_speed
      ensure_valid!
      Native.b2RevoluteJoint_GetMotorSpeed(@id)
    end

    def motor_speed=(value)
      ensure_valid!
      Native.b2RevoluteJoint_SetMotorSpeed(@id, ValueConversion.finite_float(value, label: "motor_speed"))
    end

    def motor_enabled?
      ensure_valid!
      Native.b2RevoluteJoint_IsMotorEnabled(@id)
    end

    def motor_enabled=(value)
      ensure_valid!
      Native.b2RevoluteJoint_EnableMotor(@id, !!value)
    end

    def limits
      ensure_valid!
      Native.b2RevoluteJoint_GetLowerLimit(@id)..Native.b2RevoluteJoint_GetUpperLimit(@id)
    end

    def limits=(range)
      ensure_valid!
      Native.b2RevoluteJoint_SetLimits(
        @id,
        ValueConversion.finite_float(range.begin, label: "lower_limit"),
        ValueConversion.finite_float(range.end, label: "upper_limit")
      )
      Native.b2RevoluteJoint_EnableLimit(@id, true)
    end
  end

  class PrismaticJoint < Joint
    def translation
      ensure_valid!
      Native.b2PrismaticJoint_GetTranslation(@id)
    end

    def speed
      ensure_valid!
      Native.b2PrismaticJoint_GetSpeed(@id)
    end

    def motor_speed
      ensure_valid!
      Native.b2PrismaticJoint_GetMotorSpeed(@id)
    end

    def motor_speed=(value)
      ensure_valid!
      Native.b2PrismaticJoint_SetMotorSpeed(@id, ValueConversion.finite_float(value, label: "motor_speed"))
    end

    def limits=(range)
      ensure_valid!
      Native.b2PrismaticJoint_SetLimits(
        @id,
        ValueConversion.finite_float(range.begin, label: "lower_limit"),
        ValueConversion.finite_float(range.end, label: "upper_limit")
      )
      Native.b2PrismaticJoint_EnableLimit(@id, true)
    end
  end

  class DistanceJoint < Joint
    def length
      ensure_valid!
      Native.b2DistanceJoint_GetLength(@id)
    end

    def length=(value)
      ensure_valid!
      Native.b2DistanceJoint_SetLength(@id, ValueConversion.positive_float(value, label: "length"))
    end

    def current_length
      ensure_valid!
      Native.b2DistanceJoint_GetCurrentLength(@id)
    end

    def motor_speed
      ensure_valid!
      Native.b2DistanceJoint_GetMotorSpeed(@id)
    end

    def motor_speed=(value)
      ensure_valid!
      Native.b2DistanceJoint_SetMotorSpeed(@id, ValueConversion.finite_float(value, label: "motor_speed"))
    end
  end

  class MouseJoint < Joint
    def target
      ensure_valid!
      ValueConversion.vec2(Native.b2MouseJoint_GetTarget(@id))
    end

    def target=(value)
      ensure_valid!
      Native.b2MouseJoint_SetTarget(@id, ValueConversion.native_vec2(value, label: "target"))
    end
  end

  class WeldJoint < Joint
    def reference_angle
      ensure_valid!
      Native.b2WeldJoint_GetReferenceAngle(@id)
    end

    def reference_angle=(value)
      ensure_valid!
      Native.b2WeldJoint_SetReferenceAngle(@id, ValueConversion.finite_float(value, label: "reference_angle"))
    end
  end
end
