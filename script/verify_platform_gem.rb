# frozen_string_literal: true

require "tmpdir"
require "rbconfig"
require "rubygems/package"

gem_path = File.expand_path(ARGV.fetch(0))
abort "platform gem does not exist: #{gem_path}" unless File.file?(gem_path)

specification = Gem::Package.new(gem_path).spec
if specification.platform == Gem::Platform::RUBY
  abort "expected a platform gem, got the source gem: #{gem_path}"
end

Dir.mktmpdir("box2d-platform-gem") do |directory|
  Gem::Package.new(gem_path).extract_files(directory)
  native_library = Dir[File.join(directory, "lib/box2d/native.{bundle,so,dll}")].first
  abort "platform gem does not contain a native library" unless native_library

  rspec = Gem.bin_path("rspec-core", "rspec")
  environment = {"BOX2D_LIBRARY_PATH" => native_library}
  success = system(environment, RbConfig.ruby, rspec, "--format", "progress")
  abort "specs failed against #{File.basename(gem_path)}" unless success
end
