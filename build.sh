#!/usr/bin/env bash

BUILD_DIR=${BUILD_DIR:-build}

rm -rf "$BUILD_DIR" \
  && mkdir -p "$BUILD_DIR" \
  && cd "$BUILD_DIR" \
  && cmake .. \
  && cmake --build . -j