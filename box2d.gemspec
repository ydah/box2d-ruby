# frozen_string_literal: true

require_relative "lib/box2d/version"

Gem::Specification.new do |spec|
  spec.name = "box2d-ruby"
  spec.version = Box2D::VERSION
  spec.authors = ["Yudai Takada"]
  spec.email = ["t.yudai92@gmail.com"]

  spec.summary = "Idiomatic Ruby bindings for the Box2D v3 physics engine"
  spec.description = "A generated FFI binding and memory-safe Ruby API for Box2D v3."
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.2.0"
  spec.metadata["rubygems_mfa_required"] = "true"

  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |file|
      file == gemspec || file.start_with?(*%w[bin/ Gemfile .gitignore .rspec spec/ .github/ .idea/ .serena/])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |file| File.basename(file) }
  spec.extensions = ["ext/box2d/extconf.rb"]
  spec.require_paths = ["lib"]

  spec.add_dependency "ffi", "~> 1.17"

  spec.add_development_dependency "ffi-clang", "~> 0.16"
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rspec", "~> 3.13"
end
