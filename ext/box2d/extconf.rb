# frozen_string_literal: true

require "mkmf"
require "shellwords"

cmake = find_executable("cmake")
abort "CMake 3.16 or newer is required to build box2d-ruby from source" unless cmake

build_directory = File.expand_path("cmake-build", __dir__)
configure = [
  cmake,
  "-S", __dir__,
  "-B", build_directory,
  "-DCMAKE_BUILD_TYPE=Release"
]
build = [cmake, "--build", build_directory, "--config", "Release", "--target", "box2d_vendor"]

abort "CMake configuration failed for vendored Box2D" unless system(*configure)
abort "CMake build failed for vendored Box2D" unless system(*build)

archive = Dir[File.join(build_directory, "lib", "*box2d_vendor*.{a,lib}")].first
abort "CMake did not produce the vendored Box2D static library" unless archive

$srcs = ["native.c"]
$LIBRUBYARG_SHARED = ""
$LIBRUBYARG_STATIC = ""

escaped_archive = Shellwords.escape(archive)
case RbConfig::CONFIG.fetch("host_os")
when /darwin/
  $LDFLAGS << " -Wl,-force_load,#{escaped_archive}"
when /mswin/
  $LOCAL_LIBS << " /WHOLEARCHIVE:#{escaped_archive}"
else
  $LOCAL_LIBS << " -Wl,--whole-archive #{escaped_archive} -Wl,--no-whole-archive"
end

create_makefile("box2d/native")
