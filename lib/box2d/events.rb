# frozen_string_literal: true

module Box2D
  ContactBegin = Data.define(:shape_a, :shape_b, :manifold)
  ContactEnd = Data.define(:shape_a, :shape_b)
  ContactHit = Data.define(:shape_a, :shape_b, :point, :normal, :approach_speed)
  SensorBegin = Data.define(:sensor, :visitor)
  SensorEnd = Data.define(:sensor, :visitor)
  Manifold = Data.define(:normal, :points)
  ManifoldPoint = Data.define(:point, :separation, :normal_impulse, :tangent_impulse, :persisted)

  class Events
    EMPTY = [].freeze

    attr_reader :begin_contacts, :end_contacts, :hits, :sensor_begins, :sensor_ends

    def self.empty
      new(
        begin_contacts: EMPTY,
        end_contacts: EMPTY,
        hits: EMPTY,
        sensor_begins: EMPTY,
        sensor_ends: EMPTY
      )
    end

    def self.capture(world)
      contact_events = Native.b2World_GetContactEvents(world.id)
      sensor_events = Native.b2World_GetSensorEvents(world.id)
      new(
        begin_contacts: read_array(contact_events[:beginEvents], contact_events[:beginCount], Native::ContactBeginTouchEvent) do |event|
          ContactBegin.new(
            shape_a: world.shape_for_id(event[:shapeIdA]),
            shape_b: world.shape_for_id(event[:shapeIdB]),
            manifold: capture_manifold(event[:manifold])
          )
        end,
        end_contacts: read_array(contact_events[:endEvents], contact_events[:endCount], Native::ContactEndTouchEvent) do |event|
          ContactEnd.new(
            shape_a: world.shape_for_id(event[:shapeIdA]),
            shape_b: world.shape_for_id(event[:shapeIdB])
          )
        end,
        hits: read_array(contact_events[:hitEvents], contact_events[:hitCount], Native::ContactHitEvent) do |event|
          ContactHit.new(
            shape_a: world.shape_for_id(event[:shapeIdA]),
            shape_b: world.shape_for_id(event[:shapeIdB]),
            point: ValueConversion.vec2(event[:point]),
            normal: ValueConversion.vec2(event[:normal]),
            approach_speed: event[:approachSpeed]
          )
        end,
        sensor_begins: read_array(sensor_events[:beginEvents], sensor_events[:beginCount], Native::SensorBeginTouchEvent) do |event|
          SensorBegin.new(
            sensor: world.shape_for_id(event[:sensorShapeId]),
            visitor: world.shape_for_id(event[:visitorShapeId])
          )
        end,
        sensor_ends: read_array(sensor_events[:endEvents], sensor_events[:endCount], Native::SensorEndTouchEvent) do |event|
          SensorEnd.new(
            sensor: world.shape_for_id(event[:sensorShapeId]),
            visitor: world.shape_for_id(event[:visitorShapeId])
          )
        end
      )
    end

    def initialize(begin_contacts:, end_contacts:, hits:, sensor_begins:, sensor_ends:)
      @begin_contacts = begin_contacts.freeze
      @end_contacts = end_contacts.freeze
      @hits = hits.freeze
      @sensor_begins = sensor_begins.freeze
      @sensor_ends = sensor_ends.freeze
      freeze
    end

    class << self
      private

      def read_array(pointer, count, struct_class)
        return [] if count.zero?

        Array.new(count) do |index|
          yield struct_class.new(pointer + index * struct_class.size)
        end
      end

      def capture_manifold(manifold)
        points = Array.new(manifold[:pointCount]) do |index|
          point = Native::ManifoldPoint.new(manifold[:points].to_ptr + index * Native::ManifoldPoint.size)
          ManifoldPoint.new(
            point: ValueConversion.vec2(point[:point]),
            separation: point[:separation],
            normal_impulse: point[:normalImpulse],
            tangent_impulse: point[:tangentImpulse],
            persisted: point[:persisted]
          )
        end
        Manifold.new(normal: ValueConversion.vec2(manifold[:normal]), points: points.freeze)
      end
    end
  end
end
