# frozen_string_literal: true

require_relative "lib/box2d/version"

Gem::Specification.new do |spec|
  precompiled = ENV["BOX2D_PRECOMPILED"] == "true"
  spec.name = "box2d-ruby"
  spec.version = Box2D::VERSION
  spec.authors = ["Yudai Takada"]
  spec.email = ["t.yudai92@gmail.com"]

  spec.summary = "Idiomatic Ruby bindings for the Box2D v3 physics engine"
  spec.description = "A generated FFI binding and memory-safe Ruby API for Box2D v3."
  spec.homepage = "https://rubygems.org/gems/box2d-ruby"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.2.0"
  spec.metadata["rubygems_mfa_required"] = "true"
  spec.metadata["homepage_uri"] = spec.homepage

  spec.files = Dir.chdir(__dir__) do
    Dir[
      "lib/**/*",
      "ext/box2d/CMakeLists.txt",
      "ext/box2d/extconf.rb",
      "ext/box2d/native.c",
      "ext/box2d/vendor/**/*",
      "generator/**/*",
      "script/**/*",
      "examples/**/*",
      "README.md",
      "LICENSE.txt"
    ].select { |file| File.file?(file) }
  end
  if precompiled
    native_library = Dir[File.join(__dir__, "lib/box2d/native.{bundle,so,dll}")].first
    raise "precompiled native library is missing" unless native_library

    spec.files.reject! { |file| file.start_with?("ext/", "generator/", "script/") }
    spec.files << native_library.delete_prefix("#{__dir__}/")
    local_platform = Gem::Platform.local
    spec.platform = if local_platform.os == "darwin"
      Gem::Platform.new([local_platform.cpu, "darwin", nil])
    else
      local_platform
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |file| File.basename(file) }
  spec.extensions = ["ext/box2d/extconf.rb"] unless precompiled
  spec.require_paths = ["lib"]

  spec.add_dependency "ffi", "~> 1.17"
end
