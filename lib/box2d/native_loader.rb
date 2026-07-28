# frozen_string_literal: true

require "rbconfig"

module Box2D
  module NativeLoader
    module_function

    ENVIRONMENT_KEY = "BOX2D_LIBRARY_PATH"
    EXTENSION_NAME = "native.#{RbConfig::CONFIG.fetch("DLEXT")}"

    def library_path
      explicit_path = ENV[ENVIRONMENT_KEY]
      return validate_explicit_path(explicit_path) if explicit_path

      path = candidates.find { |candidate| File.file?(candidate) }
      return path if path

      raise LoadError, missing_library_message
    end

    def candidates
      relative_path = File.join("box2d", EXTENSION_NAME)
      load_path_candidates = $LOAD_PATH.map { |path| File.expand_path(relative_path, path) }
      source_candidate = File.expand_path("../../ext/box2d/#{EXTENSION_NAME}", __dir__)

      (load_path_candidates << source_candidate).uniq
    end

    def validate_explicit_path(path)
      expanded_path = File.expand_path(path)
      return expanded_path if File.file?(expanded_path)

      raise LoadError, "#{ENVIRONMENT_KEY} does not point to a file: #{expanded_path}"
    end

    def missing_library_message
      <<~MESSAGE.chomp
        Box2D native library was not found. Reinstall the gem to build it, run
        `bundle exec rake native:compile` from a source checkout, or set
        #{ENVIRONMENT_KEY} to a compatible Box2D 3.1 shared library.
      MESSAGE
    end
  end
end
