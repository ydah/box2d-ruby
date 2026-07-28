# frozen_string_literal: true

require "bundler/gem_tasks"
require "rspec/core/rake_task"
require "rake/clean"
require "rbconfig"
require "tmpdir"

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

task spec: "bindings:check"
task default: :spec
