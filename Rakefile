# frozen_string_literal: true

require "bundler/gem_tasks"
require "rspec/core/rake_task"
require "rake/clean"
require "rbconfig"
require "tmpdir"
require_relative "lib/box2d/version"

RSpec::Core::RakeTask.new(:spec)

extension_directory = File.expand_path("ext/box2d", __dir__)
extension_name = "native.#{RbConfig::CONFIG.fetch("DLEXT")}"
extension_path = File.join(extension_directory, extension_name)

CLEAN.include(
  File.join(extension_directory, "Makefile"),
  File.join(extension_directory, "cmake-build"),
  File.join(extension_directory, "mkmf.log"),
  extension_path,
  File.join(extension_directory, "*.o")
)

namespace :native do
  desc "Compile the vendored Box2D native extension with CMake"
  task :compile do
    Dir.chdir(extension_directory) do
      sh RbConfig.ruby, "extconf.rb"
      sh ENV.fetch("MAKE", "make")
    end
  end

  desc "Build a platform gem containing the compiled native library"
  task package: :compile do
    sh RbConfig.ruby, "script/build_platform_gem.rb"
  end

  desc "Run the full spec suite against the packaged native library"
  task verify_package: :package do
    source_gem = "box2d-ruby-#{Box2D::VERSION}.gem"
    platform_gem = Dir[File.join("pkg", "box2d-ruby-#{Box2D::VERSION}-*.gem")]
      .reject { |path| File.basename(path) == source_gem }
      .max_by { |path| File.mtime(path) }
    abort "the platform gem was not built" unless platform_gem

    sh RbConfig.ruby, "script/verify_platform_gem.rb", platform_gem
  end
end

namespace :bindings do
  desc "Regenerate FFI declarations from the vendored Box2D headers"
  task :generate do
    sh RbConfig.ruby, "generator/generate.rb"
  end

  desc "Check generated FFI declarations and native ABI layouts"
  task check: ["native:compile"] do
    sh RbConfig.ruby, "generator/generate.rb", "--check"

    Dir.mktmpdir("box2d-layouts") do |directory|
      executable = File.join(directory, "layout_probe")
      sh(
        ENV.fetch("CC", RbConfig::CONFIG.fetch("CC", "cc")),
        "-std=c17",
        "-Iext/box2d/vendor/box2d/include",
        "generator/layout_probe.c",
        "-o",
        executable
      )
      sh RbConfig.ruby, "generator/verify_layouts.rb", executable
    end
  end
end

namespace :snapshots do
  desc "Update the deterministic snapshot for the current platform"
  task update: "native:compile" do
    sh RbConfig.ruby, "script/update_deterministic_snapshot.rb"
  end
end

task spec: "bindings:check"
task default: :spec
