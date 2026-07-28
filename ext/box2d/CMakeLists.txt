cmake_minimum_required(VERSION 3.16)

project(box2d_ruby_vendor LANGUAGES C)

file(GLOB BOX2D_VENDOR_SOURCES CONFIGURE_DEPENDS
  "${CMAKE_CURRENT_SOURCE_DIR}/vendor/box2d/src/*.c"
)

add_library(box2d_vendor STATIC ${BOX2D_VENDOR_SOURCES})

target_include_directories(box2d_vendor
  PUBLIC "${CMAKE_CURRENT_SOURCE_DIR}/vendor/box2d/include"
  PRIVATE "${CMAKE_CURRENT_SOURCE_DIR}/vendor/box2d/src"
)
target_compile_definitions(box2d_vendor PRIVATE B2_ENABLE_ASSERT box2d_EXPORTS)

set_target_properties(box2d_vendor PROPERTIES
  ARCHIVE_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/lib"
  C_STANDARD 17
  C_STANDARD_REQUIRED YES
  C_EXTENSIONS YES
  POSITION_INDEPENDENT_CODE ON
)

foreach(configuration DEBUG RELEASE RELWITHDEBINFO MINSIZEREL)
  set_target_properties(box2d_vendor PROPERTIES
    "ARCHIVE_OUTPUT_DIRECTORY_${configuration}" "${CMAKE_BINARY_DIR}/lib"
  )
endforeach()

if(MSVC)
  target_compile_options(box2d_vendor PRIVATE /fp:strict)
else()
  target_compile_options(box2d_vendor PRIVATE -ffp-contract=off)
endif()
