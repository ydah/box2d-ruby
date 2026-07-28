# frozen_string_literal: true

module Box2D
  module WorldRegistry
    def body_for_id(id)
      key = ValueConversion.id_key(id)
      @bodies[key] ||= Body.new(self, id)
    end

    def shape_for_id(id)
      key = ValueConversion.id_key(id)
      return @shapes[key] if @shapes.key?(key)

      body = body_for_id(Native.b2Shape_GetBody(id)) if Native.b2Shape_IsValid(id)
      @shapes[key] = Shape.new(self, id, body:)
    end

    def register_body(body)
      @bodies[ValueConversion.id_key(body.id)] = body
      body
    end

    def register_shape(shape)
      @shapes[ValueConversion.id_key(shape.id)] = shape
      shape
    end

    def register_chain(chain)
      @chains[ValueConversion.id_key(chain.id)] = chain
      chain
    end

    def unregister_body(body)
      @bodies.delete(ValueConversion.id_key(body.id))
      @body_user_data.delete(ValueConversion.id_key(body.id))
      body.shapes.each { |shape| unregister_shape(shape) }
      body.chains.each { |chain| unregister_chain(chain) }
    end

    def unregister_shape(shape)
      key = ValueConversion.id_key(shape.id)
      @shapes.delete(key)
      @shape_user_data.delete(key)
    end

    def unregister_chain(chain)
      @chains.delete(ValueConversion.id_key(chain.id))
    end

    def body_user_data(body)
      @body_user_data[ValueConversion.id_key(body.id)]
    end

    def set_body_user_data(body, value)
      @body_user_data[ValueConversion.id_key(body.id)] = value
    end

    def shape_user_data(shape)
      @shape_user_data[ValueConversion.id_key(shape.id)]
    end

    def set_shape_user_data(shape, value)
      @shape_user_data[ValueConversion.id_key(shape.id)] = value
    end

    private

    def initialize_registries
      @bodies = {}
      @shapes = {}
      @chains = {}
      @body_user_data = {}
      @shape_user_data = {}
    end

    def clear_registries
      [@bodies, @shapes, @chains].each do |registry|
        registry.each_value { |handle| handle.send(:invalidate!) }
        registry.clear
      end
      @body_user_data.clear
      @shape_user_data.clear
    end
  end
end
