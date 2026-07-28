# frozen_string_literal: true

module Box2D
  module BodyShapes
    def box(half_width, half_height, center: [0, 0], angle: 0, **options)
      ensure_valid!
      width = ValueConversion.positive_float(half_width, label: "half_width")
      height = ValueConversion.positive_float(half_height, label: "half_height")
      polygon = Native.b2MakeOffsetBox(
        width,
        height,
        ValueConversion.native_vec2(center, label: "center"),
        ValueConversion.native_rot(angle)
      )
      create_shape(:b2CreatePolygonShape, polygon, options)
    end

    def circle(radius:, center: [0, 0], **options)
      ensure_valid!
      geometry = Native::Circle.new
      geometry[:center] = ValueConversion.native_vec2(center, label: "center")
      geometry[:radius] = ValueConversion.positive_float(radius, label: "radius")
      create_shape(:b2CreateCircleShape, geometry, options)
    end

    def capsule(point1, point2, radius:, **options)
      ensure_valid!
      geometry = Native::Capsule.new
      geometry[:center1] = ValueConversion.native_vec2(point1, label: "point1")
      geometry[:center2] = ValueConversion.native_vec2(point2, label: "point2")
      geometry[:radius] = ValueConversion.positive_float(radius, label: "radius")
      create_shape(:b2CreateCapsuleShape, geometry, options)
    end

    def polygon(points, radius: 0.0, **options)
      ensure_valid!
      point_buffer, count = native_points(points, minimum: 3, maximum: 8)
      hull = Native.b2ComputeHull(point_buffer, count)
      raise ArgumentError, "points do not form a valid convex hull" if hull[:count] < 3

      polygon = Native.b2MakePolygon(
        hull.pointer,
        ValueConversion.non_negative_float(radius, label: "radius")
      )
      create_shape(:b2CreatePolygonShape, polygon, options)
    end

    def segment(point1, point2, **options)
      ensure_valid!
      geometry = Native::Segment.new
      geometry[:point1] = ValueConversion.native_vec2(point1, label: "point1")
      geometry[:point2] = ValueConversion.native_vec2(point2, label: "point2")
      create_shape(:b2CreateSegmentShape, geometry, options)
    end

    def chain(points, loop: false, **options)
      ensure_valid!
      point_buffer, count = native_points(points, minimum: 4)
      definition = Native.b2DefaultChainDef
      definition[:points] = point_buffer
      definition[:count] = count
      definition[:isLoop] = !!loop
      definition[:enableSensorEvents] = !!options.fetch(:sensor_events, true)
      ShapeDefinition.apply_filter(definition[:filter], options.fetch(:filter, {}))

      material_buffer = FFI::MemoryPointer.new(Native::SurfaceMaterial)
      material = Native.b2DefaultSurfaceMaterial
      configure_material(material, options)
      material_buffer.put_bytes(0, material.pointer.read_bytes(Native::SurfaceMaterial.size))
      definition[:materials] = material_buffer
      definition[:materialCount] = 1

      native_id = Native.b2CreateChain(@id, definition.pointer)
      chain = Chain.new(@world, native_id, body: self)
      @chains << chain
      @world.register_chain(chain)
    end

    private

    def create_shape(function, geometry, options)
      definition = ShapeDefinition.build(options)
      native_id = Native.public_send(function, @id, definition.pointer, geometry.pointer)
      shape = Shape.new(@world, native_id, body: self)
      shape.user_data = options[:user_data] if options.key?(:user_data)
      @shapes << shape
      @world.register_shape(shape)
    end

    def native_points(points, minimum:, maximum: nil)
      values = points.to_a
      valid = values.length >= minimum && (!maximum || values.length <= maximum)
      range = maximum ? "#{minimum}..#{maximum}" : "at least #{minimum}"
      raise ArgumentError, "points must contain #{range} vertices" unless valid

      pointer = FFI::MemoryPointer.new(Native::Vec2, values.length)
      values.each_with_index do |point, index|
        vector = ValueConversion.native_vec2(point, label: "points[#{index}]")
        pointer.put_bytes(index * Native::Vec2.size, vector.pointer.read_bytes(Native::Vec2.size))
      end
      [pointer, values.length]
    end

    def configure_material(material, options)
      material[:friction] = ValueConversion.non_negative_float(options.fetch(:friction, 0.6), label: "friction")
      material[:restitution] = ShapeDefinition.coefficient(options.fetch(:restitution, 0.0), "restitution")
      material[:rollingResistance] = ShapeDefinition.coefficient(
        options.fetch(:rolling_resistance, 0.0),
        "rolling_resistance"
      )
      material[:tangentSpeed] = ValueConversion.finite_float(options.fetch(:tangent_speed, 0.0), label: "tangent_speed")
      material[:userMaterialId] = Integer(options.fetch(:material, 0))
    end
  end
end
