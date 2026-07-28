# frozen_string_literal: true

module Box2D
  class Shape < Handle
    ID_CLASS = Native::ShapeId
    TYPES = {
      Native::ShapeType::CIRCLE_SHAPE => :circle,
      Native::ShapeType::CAPSULE_SHAPE => :capsule,
      Native::ShapeType::SEGMENT_SHAPE => :segment,
      Native::ShapeType::POLYGON_SHAPE => :polygon,
      Native::ShapeType::CHAIN_SEGMENT_SHAPE => :chain_segment
    }.freeze

    attr_reader :body

    def initialize(world, id, body: nil)
      super(world, id)
      @body = body
    end

    def destroy
      ensure_valid!
      Native.b2DestroyShape(@id, true)
      invalidate!
      @world.unregister_shape(self)
      @body&.unregister_shape(self)
      true
    end

    def type
      ensure_valid!
      TYPES.fetch(Native.b2Shape_GetType(@id))
    end

    def sensor?
      ensure_valid!
      Native.b2Shape_IsSensor(@id)
    end

    def density
      ensure_valid!
      Native.b2Shape_GetDensity(@id)
    end

    def density=(value)
      ensure_valid!
      Native.b2Shape_SetDensity(@id, ValueConversion.non_negative_float(value, label: "density"), true)
    end

    def friction
      ensure_valid!
      Native.b2Shape_GetFriction(@id)
    end

    def friction=(value)
      ensure_valid!
      Native.b2Shape_SetFriction(@id, ValueConversion.non_negative_float(value, label: "friction"))
    end

    def restitution
      ensure_valid!
      Native.b2Shape_GetRestitution(@id)
    end

    def restitution=(value)
      ensure_valid!
      Native.b2Shape_SetRestitution(@id, ShapeDefinition.send(:coefficient, value, "restitution"))
    end

    def filter
      ensure_valid!
      native_filter = Native.b2Shape_GetFilter(@id)
      {
        category: native_filter[:categoryBits],
        mask: native_filter[:maskBits],
        group: native_filter[:groupIndex]
      }
    end

    def filter=(options)
      ensure_valid!
      native_filter = Native.b2Shape_GetFilter(@id)
      ShapeDefinition.apply_filter(native_filter, options)
      Native.b2Shape_SetFilter(@id, native_filter)
    end

    def user_data
      ensure_valid!
      @world.shape_user_data(self)
    end

    def user_data=(value)
      ensure_valid!
      @world.set_shape_user_data(self, value)
    end

    def aabb
      ensure_valid!
      bounds = Native.b2Shape_GetAABB(@id)
      [ValueConversion.vec2(bounds[:lowerBound]), ValueConversion.vec2(bounds[:upperBound])]
    end

    protected

    def native_valid?
      Native.b2Shape_IsValid(@id)
    end
  end
end
