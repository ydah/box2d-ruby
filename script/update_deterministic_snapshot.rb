# frozen_string_literal: true

require "json"
require "fileutils"
require_relative "../lib/box2d"
require_relative "deterministic_scene"

path = DeterministicScene.snapshot_path
FileUtils.mkdir_p(File.dirname(path))
File.write(path, JSON.pretty_generate(DeterministicScene.capture) << "\n")
puts path
