BUILD_DIR=${BUILD_DIR:-build}

mkdir -p "$BUILD_DIR" \
  && cd "$BUILD_DIR" \
  && cmake ..\
  && cmake --build . \
  && ./skynet examples/config