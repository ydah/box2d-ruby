# frozen_string_literal: true

module Box2D
  class Body < Handle
    include BodyShapes

    ID_CLASS = Native::BodyId
    TYPES = {
      Native::BodyType::STATIC_BODY => :static,
      Native::BodyType::KINEMATIC_BODY => :kinematic,
      Native::BodyType::DYNAMIC_BODY => :dynamic
    }.freeze
    TYPE_VALUES = TYPES.invert.freeze

    attr_reader :shapes, :chains

    def initialize(world, id)
      super
      @shapes = []
      @chains = []
    end

    def destroy
      ensure_valid!
      Native.b2DestroyBody(@id)
      @shapes.each { |shape| shape.send(:invalidate!) }
      @chains.each { |chain| chain.send(:invalidate!) }
      invalidate!
      @world.unregister_body(self)
      true
    end

    def type
      ensure_valid!
      TYPES.fetch(Native.b2Body_GetType(@id))
    end

    def type=(value)
      ensure_valid!
      Native.b2Body_SetType(@id, TYPE_VALUES.fetch(value) { raise ArgumentError, "invalid body type: #{value.inspect}" })
    end

    def position
      ensure_valid!
      ValueConversion.vec2(Native.b2Body_GetPosition(@id))
    end

    def position=(value)
      ensure_valid!
      Native.b2Body_SetTransform(@id, ValueConversion.native_vec2(value, label: "position"), Native.b2Body_GetRotation(@id))
    end

    def angle
      ensure_valid!
      rotation = Native.b2Body_GetRotation(@id)
      Math.atan2(rotation[:s], rotation[:c])
    end

    def angle=(value)
      ensure_valid!
      Native.b2Body_SetTransform(@id, Native.b2Body_GetPosition(@id), ValueConversion.native_rot(value))
    end

    def linear_velocity
      ensure_valid!
      ValueConversion.vec2(Native.b2Body_GetLinearVelocity(@id))
    end

    def linear_velocity=(value)
      ensure_valid!
      Native.b2Body_SetLinearVelocity(@id, ValueConversion.native_vec2(value, label: "linear_velocity"))
    end

    def angular_velocity
      ensure_valid!
      Native.b2Body_GetAngularVelocity(@id)
    end

    def angular_velocity=(value)
      ensure_valid!
      Native.b2Body_SetAngularVelocity(@id, ValueConversion.finite_float(value, label: "angular_velocity"))
    end

    def apply_impulse(impulse, point: nil, wake: true)
      ensure_valid!
      native_impulse = ValueConversion.native_vec2(impulse, label: "impulse")
      if point
        Native.b2Body_ApplyLinearImpulse(@id, native_impulse, ValueConversion.native_vec2(point, label: "point"), !!wake)
      else
        Native.b2Body_ApplyLinearImpulseToCenter(@id, native_impulse, !!wake)
      end
      self
    end

    def apply_force(force, point: nil, wake: true)
      ensure_valid!
      native_force = ValueConversion.native_vec2(force, label: "force")
      if point
        Native.b2Body_ApplyForce(@id, native_force, ValueConversion.native_vec2(point, label: "point"), !!wake)
      else
        Native.b2Body_ApplyForceToCenter(@id, native_force, !!wake)
      end
      self
    end

    def apply_torque(torque, wake: true)
      ensure_valid!
      Native.b2Body_ApplyTorque(@id, ValueConversion.finite_float(torque, label: "torque"), !!wake)
      self
    end

    def mass
      ensure_valid!
      Native.b2Body_GetMass(@id)
    end

    def awake?
      ensure_valid!
      Native.b2Body_IsAwake(@id)
    end

    def awake=(value)
      ensure_valid!
      Native.b2Body_SetAwake(@id, !!value)
    end

    def bullet?
      ensure_valid!
      Native.b2Body_IsBullet(@id)
    end

    def bullet=(value)
      ensure_valid!
      Native.b2Body_SetBullet(@id, !!value)
    end

    def user_data
      ensure_valid!
      @world.body_user_data(self)
    end

    def user_data=(value)
      ensure_valid!
      @world.set_body_user_data(self, value)
    end

    def unregister_shape(shape)
      @shapes.delete(shape)
    end

    def unregister_chain(chain)
      @chains.delete(chain)
    end

    protected

    def native_valid?
      Native.b2Body_IsValid(@id)
    end
  end
end
