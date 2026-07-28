# frozen_string_literal: true

require "mkmf"

vendor_root = File.expand_path("vendor/box2d", __dir__)
source_root = File.join(vendor_root, "src")
abort "vendored Box2D source is missing" unless File.file?(File.join(source_root, "world.c"))

$srcs = ["native.c", *Dir[File.join(source_root, "*.c")]]
$VPATH << source_root
$INCFLAGS << " -I$(srcdir)/vendor/box2d/include -I$(srcdir)/vendor/box2d/src"
$defs << "-Dbox2d_EXPORTS"
$CFLAGS << " -std=c17 -ffp-contract=off"
$LIBRUBYARG_SHARED = ""
$LIBRUBYARG_STATIC = ""

create_makefile("box2d/native")
