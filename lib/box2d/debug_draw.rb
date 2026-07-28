# frozen_string_literal: true

module Box2D
  class DebugDraw
    FLAG_FIELDS = {
      shapes: :drawShapes,
      joints: :drawJoints,
      joint_extras: :drawJointExtras,
      aabbs: :drawBounds,
      bounds: :drawBounds,
      mass: :drawMass,
      body_names: :drawBodyNames,
      contacts: :drawContacts,
      graph_colors: :drawGraphColors,
      contact_normals: :drawContactNormals,
      contact_impulses: :drawContactImpulses,
      contact_features: :drawContactFeatures,
      friction_impulses: :drawFrictionImpulses,
      islands: :drawIslands
    }.freeze

    attr_reader :definition, :callbacks

    def initialize(flags, &block)
      @block = block
      @error = nil
      @definition = Native.b2DefaultDebugDraw
      @callbacks = []
      configure_flags(flags)
      configure_callbacks
    end

    def raise_callback_error
      raise @error if @error
    end

    private

    def configure_flags(flags)
      flags.each do |flag|
        field = FLAG_FIELDS.fetch(flag) { raise ArgumentError, "unknown debug draw flag: #{flag.inspect}" }
        @definition[field] = true
      end
    end

    def configure_callbacks
      callback(:DrawPolygonFcn, :void, [:pointer, :int, :int, :pointer]) do |vertices, count, color, _context|
        emit([:polygon, points(vertices, count), color])
      end
      callback(
        :DrawSolidPolygonFcn,
        :void,
        [Native::Transform.by_value, :pointer, :int, :float, :int, :pointer]
      ) do |transform, vertices, count, radius, color, _context|
        emit([:solid_polygon, transform_value(transform), points(vertices, count), radius, color])
      end
      callback(:DrawCircleFcn, :void, [Native::Vec2.by_value, :float, :int, :pointer]) do |center, radius, color, _context|
        emit([:circle, ValueConversion.vec2(center), radius, color])
      end
      callback(
        :DrawSolidCircleFcn,
        :void,
        [Native::Transform.by_value, :float, :int, :pointer]
      ) do |transform, radius, color, _context|
        emit([:solid_circle, transform_value(transform), radius, color])
      end
      callback(
        :DrawSolidCapsuleFcn,
        :void,
        [Native::Vec2.by_value, Native::Vec2.by_value, :float, :int, :pointer]
      ) do |point1, point2, radius, color, _context|
        emit([:solid_capsule, ValueConversion.vec2(point1), ValueConversion.vec2(point2), radius, color])
      end
      callback(
        :DrawSegmentFcn,
        :void,
        [Native::Vec2.by_value, Native::Vec2.by_value, :int, :pointer]
      ) do |point1, point2, color, _context|
        emit([:segment, ValueConversion.vec2(point1), ValueConversion.vec2(point2), color])
      end
      callback(:DrawTransformFcn, :void, [Native::Transform.by_value, :pointer]) do |transform, _context|
        emit([:transform, transform_value(transform)])
      end
      callback(:DrawPointFcn, :void, [Native::Vec2.by_value, :float, :int, :pointer]) do |point, size, color, _context|
        emit([:point, ValueConversion.vec2(point), size, color])
      end
      callback(:DrawStringFcn, :void, [Native::Vec2.by_value, :pointer, :int, :pointer]) do |point, string, color, _context|
        emit([:string, ValueConversion.vec2(point), string.read_string, color])
      end
    end

    def callback(field, result, arguments, &block)
      function = FFI::Function.new(result, arguments, &block)
      @callbacks << function
      @definition[field] = function
    end

    def points(pointer, count)
      Array.new(count) do |index|
        ValueConversion.vec2(Native::Vec2.new(pointer + index * Native::Vec2.size))
      end
    end

    def transform_value(transform)
      rotation = transform[:q]
      {
        position: ValueConversion.vec2(transform[:p]),
        angle: Math.atan2(rotation[:s], rotation[:c])
      }
    end

    def emit(command)
      @block.call(command)
    rescue Exception => error
      @error ||= error
    end
  end
end
