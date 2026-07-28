# frozen_string_literal: true

require "bundler/gem_tasks"
require "rspec/core/rake_task"
require "rake/clean"
require "rbconfig"

RSpec::Core::RakeTask.new(:spec)

extension_directory = File.expand_path("ext/box2d", __dir__)
extension_name = "native.#{RbConfig::CONFIG.fetch("DLEXT")}"
extension_path = File.join(extension_directory, extension_name)

CLEAN.include(
  File.join(extension_directory, "Makefile"),
  File.join(extension_directory, "mkmf.log"),
  extension_path,
  File.join(extension_directory, "*.o")
)

namespace :native do
  desc "Compile the vendored Box2D native extension"
  task :compile do
    Dir.chdir(extension_directory) do
      sh RbConfig.ruby, "extconf.rb"
      sh ENV.fetch("MAKE", "make")
    end
  end
end

task spec: "native:compile"
task default: :spec
