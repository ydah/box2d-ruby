# frozen_string_literal: true

module Box2D
  class Chain < Handle
    ID_CLASS = Native::ChainId

    attr_reader :body

    def initialize(world, id, body: nil)
      super(world, id)
      @body = body
    end

    def destroy
      ensure_valid!
      Native.b2DestroyChain(@id)
      invalidate!
      @world.unregister_chain(self)
      @body&.unregister_chain(self)
      true
    end

    def segments
      ensure_valid!
      count = Native.b2Chain_GetSegmentCount(@id)
      pointer = FFI::MemoryPointer.new(Native::ShapeId, count)
      actual = Native.b2Chain_GetSegments(@id, pointer, count)

      Array.new(actual) do |index|
        id = Native::ShapeId.new(pointer + index * Native::ShapeId.size)
        @world.shape_for_id(id)
      end
    end

    def friction
      ensure_valid!
      Native.b2Chain_GetFriction(@id)
    end

    def friction=(value)
      ensure_valid!
      Native.b2Chain_SetFriction(@id, ValueConversion.non_negative_float(value, label: "friction"))
    end

    def restitution
      ensure_valid!
      Native.b2Chain_GetRestitution(@id)
    end

    def restitution=(value)
      ensure_valid!
      Native.b2Chain_SetRestitution(@id, ShapeDefinition.coefficient(value, "restitution"))
    end

    protected

    def native_valid?
      Native.b2Chain_IsValid(@id)
    end
  end
end
