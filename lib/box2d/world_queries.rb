# frozen_string_literal: true

module Box2D
  module WorldQueries
    def raycast(from, to, filter: {})
      ensure_access!
      origin = ValueConversion.native_vec2(from, label: "from")
      destination = ValueConversion.native_vec2(to, label: "to")
      translation = Native::Vec2.new
      translation[:x] = destination[:x] - origin[:x]
      translation[:y] = destination[:y] - origin[:y]
      result = Native.b2World_CastRayClosest(@id, origin, translation, ShapeDefinition.query_filter(filter))
      return unless result[:hit]

      Hit.new(
        shape: shape_for_id(result[:shapeId]),
        point: ValueConversion.vec2(result[:point]),
        normal: ValueConversion.vec2(result[:normal]),
        fraction: result[:fraction]
      )
    end

    def overlap_aabb(lower, upper, filter: {}, &block)
      return enum_for(__method__, lower, upper, filter:) unless block

      ensure_access!
      bounds = Native::AABB.new
      bounds[:lowerBound] = ValueConversion.native_vec2(lower, label: "lower")
      bounds[:upperBound] = ValueConversion.native_vec2(upper, label: "upper")
      if bounds[:lowerBound][:x] > bounds[:upperBound][:x] || bounds[:lowerBound][:y] > bounds[:upperBound][:y]
        raise ArgumentError, "lower AABB bound must not exceed upper bound"
      end

      perform_overlap(block) do |callback|
        Native.b2World_OverlapAABB(@id, bounds, ShapeDefinition.query_filter(filter), callback, nil)
      end
    end

    def overlap_circle(center, radius:, filter: {}, &block)
      return enum_for(__method__, center, radius:, filter:) unless block

      ensure_access!
      point = ValueConversion.native_vec2(center, label: "center")
      proxy = Native.b2MakeProxy(
        point.pointer,
        1,
        ValueConversion.positive_float(radius, label: "radius")
      )
      overlap_proxy(proxy, filter, block)
    end

    def overlap_capsule(point1, point2, radius:, filter: {}, &block)
      return enum_for(__method__, point1, point2, radius:, filter:) unless block

      ensure_access!
      points, count = native_query_points([point1, point2], minimum: 2, maximum: 2)
      proxy = Native.b2MakeProxy(
        points,
        count,
        ValueConversion.positive_float(radius, label: "radius")
      )
      overlap_proxy(proxy, filter, block)
    end

    def overlap_polygon(points, position: [0, 0], angle: 0, radius: 0.0, filter: {}, &block)
      return enum_for(__method__, points, position:, angle:, radius:, filter:) unless block

      ensure_access!
      point_buffer, count = native_query_points(points, minimum: 3, maximum: 8)
      hull = Native.b2ComputeHull(point_buffer, count)
      raise ArgumentError, "points do not form a valid convex hull" if hull[:count] < 3

      proxy = Native.b2MakeOffsetProxy(
        hull.pointer + Native::Hull.offset_of(:points),
        hull[:count],
        ValueConversion.non_negative_float(radius, label: "radius"),
        ValueConversion.native_vec2(position, label: "position"),
        ValueConversion.native_rot(angle)
      )
      overlap_proxy(proxy, filter, block)
    end

    private

    def overlap_proxy(proxy, filter, block)
      ensure_access!
      perform_overlap(block) do |callback|
        Native.b2World_OverlapShape(@id, proxy.pointer, ShapeDefinition.query_filter(filter), callback, nil)
      end
    end

    def perform_overlap(block)
      callback_error = nil
      callback = FFI::Function.new(:bool, [Native::ShapeId.by_value, :pointer]) do |shape_id, _context|
        begin
          block.call(shape_for_id(shape_id)) != false
        rescue Exception => error
          callback_error ||= error
          false
        end
      end
      yield callback
      raise callback_error if callback_error

      self
    end

    def native_query_points(points, minimum:, maximum:)
      values = points.to_a
      unless values.length.between?(minimum, maximum)
        raise ArgumentError, "points must contain #{minimum}..#{maximum} vertices"
      end

      pointer = FFI::MemoryPointer.new(Native::Vec2, values.length)
      values.each_with_index do |point, index|
        vector = ValueConversion.native_vec2(point, label: "points[#{index}]")
        pointer.put_bytes(index * Native::Vec2.size, vector.pointer.read_bytes(Native::Vec2.size))
      end
      [pointer, values.length]
    end
  end
end
