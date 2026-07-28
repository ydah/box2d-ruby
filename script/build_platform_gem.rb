# frozen_string_literal: true

require "fileutils"
require "rbconfig"
require "rubygems/package"

root = File.expand_path("..", __dir__)
extension = "native.#{RbConfig::CONFIG.fetch("DLEXT")}"
compiled_library = File.join(root, "ext/box2d", extension)
packaged_library = File.join(root, "lib/box2d", extension)
abort "compile the native library before packaging" unless File.file?(compiled_library)

begin
  FileUtils.cp(compiled_library, packaged_library)
  ENV["BOX2D_PRECOMPILED"] = "true"
  specification = Gem::Specification.load(File.join(root, "box2d.gemspec"))
  gem_file = Gem::Package.build(specification)
  FileUtils.mkdir_p(File.join(root, "pkg"))
  destination = File.join(root, "pkg", File.basename(gem_file))
  FileUtils.mv(gem_file, destination)
  puts destination
ensure
  FileUtils.rm_f(packaged_library)
end
