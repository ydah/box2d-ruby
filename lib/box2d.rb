# frozen_string_literal: true

require_relative "box2d/version"

module Box2D
  class Error < StandardError; end
  class LoadError < Error; end
  class UseAfterDestroyError < Error; end
end

require_relative "box2d/native_loader"
