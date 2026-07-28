# frozen_string_literal: true

require_relative "box2d/version"

module Box2D
  class Error < StandardError; end
  class LoadError < Error; end
  class UseAfterDestroyError < Error; end
  class ReentrantStepError < Error; end
end

require_relative "box2d/native_loader"
require_relative "box2d/native"
require_relative "box2d/value_conversion"
require_relative "box2d/fixed_stepper"
require_relative "box2d/pixel_scale"
require_relative "box2d/handle"
require_relative "box2d/shape_definition"
require_relative "box2d/shape"
require_relative "box2d/chain"
require_relative "box2d/body_shapes"
require_relative "box2d/body"
require_relative "box2d/events"
require_relative "box2d/hit"
require_relative "box2d/world_registry"
require_relative "box2d/body_definition"
require_relative "box2d/world"
