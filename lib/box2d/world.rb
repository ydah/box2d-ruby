# frozen_string_literal: true

module Box2D
  class World
    include WorldRegistry
    include BodyDefinition
    include WorldJoints
    include WorldQueries

    BODY_TYPES = Body::TYPE_VALUES

    attr_reader :id

    def initialize(gravity: [0, -9.8], substeps: 4, sleep: true, continuous: true)
      definition = Native.b2DefaultWorldDef
      definition[:gravity] = ValueConversion.native_vec2(gravity, label: "gravity")
      definition[:enableSleep] = !!sleep
      definition[:enableContinuous] = !!continuous

      @id = Native.b2CreateWorld(definition.pointer)
      @destroyed = false
      @stepping = false
      @drawing = false
      initialize_registries
      @events = Events.empty
      self.substeps = substeps

      yield self if block_given?
    rescue Exception
      destroy if @id && !@destroyed
      raise
    end

    def valid?
      raise ReentrantStepError, "the world cannot be accessed during a native operation" if @stepping || @drawing

      !@destroyed && Native.b2World_IsValid(@id)
    end

    def destroyed?
      !valid?
    end

    def destroy
      return false if @destroyed

      ensure_access!
      Native.b2DestroyWorld(@id)
      @destroyed = true
      clear_registries
      @events = Events.empty
      true
    end

    def substeps
      @substeps
    end

    def substeps=(value)
      count = Integer(value)
      raise ArgumentError, "substeps must be greater than zero" unless count.positive?

      @substeps = count
    end

    def gravity
      ensure_access!
      ValueConversion.vec2(Native.b2World_GetGravity(@id))
    end

    def gravity=(value)
      ensure_access!
      Native.b2World_SetGravity(@id, ValueConversion.native_vec2(value, label: "gravity"))
    end

    def step(delta_time)
      ensure_access!
      time_step = ValueConversion.non_negative_float(delta_time, label: "delta_time")
      @stepping = true
      begin
        Native.b2World_Step(@id, time_step, @substeps)
        @events = Events.capture(self)
        self
      ensure
        @stepping = false
      end
    end

    def events
      ensure_access!
      @events
    end

    def create_body(type: :static, position: [0, 0], angle: 0, **options)
      ensure_access!
      definition = build_body_definition(type:, position:, angle:, options:)
      body = Body.new(self, Native.b2CreateBody(@id, definition.pointer))
      register_body(body)
      body.user_data = options[:user_data] if options.key?(:user_data)

      begin
        yield body if block_given?
      rescue Exception
        body.destroy if body.valid?
        raise
      end
      body
    end

    def debug_draw(flags: [:shapes])
      raise ArgumentError, "a debug draw block is required" unless block_given?

      ensure_access!
      @debug_draw = DebugDraw.new(flags) { |command| yield command }
      @drawing = true
      begin
        Native.b2World_Draw(@id, @debug_draw.definition.pointer)
      ensure
        @drawing = false
      end
      @debug_draw.raise_callback_error
      self
    end

    def ensure_access!
      raise UseAfterDestroyError, "Box2D::World has been destroyed" if @destroyed
      if @stepping || @drawing
        raise ReentrantStepError, "the world cannot be accessed during a native operation"
      end

      true
    end

  end
end
