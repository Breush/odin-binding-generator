#!/bin/sh

# -----

echo "#===== Generating xcb..."
odin run ./examples/xcb/generate.odin

echo "#===== Generating vulkan..."
odin run ./examples/vulkan/generate.odin

echo "#===== Generating mini-al..."
odin run ./examples/mini-al/generate.odin

echo "#===== Generating zlib..."
odin run ./examples/zlib/generate.odin

# -----

echo "#===== Testing xcb..."
odin run ./examples/xcb/test.odin

echo "#===== Testing vulkan..."
odin run ./examples/vulkan/test.odin
