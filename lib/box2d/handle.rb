# frozen_string_literal: true

module Box2D
  class Handle
    attr_reader :world, :id

    def initialize(world, id)
      @world = world
      @id = ValueConversion.copy_struct(self.class::ID_CLASS, id)
      @key = ValueConversion.id_key(@id)
      @destroyed = false
    end

    def valid?
      !@destroyed && @world.valid? && native_valid?
    end

    def destroyed?
      !valid?
    end

    def hash
      [self.class, @world.object_id, @key].hash
    end

    def eql?(other)
      other.instance_of?(self.class) && other.world.equal?(@world) && other.key == @key
    end
    alias == eql?

    protected

    attr_reader :key

    def ensure_valid!
      @world.ensure_access!
      return if !@destroyed && native_valid?

      raise UseAfterDestroyError, "#{self.class.name} has been destroyed"
    end

    def invalidate!
      @destroyed = true
    end
  end
end
