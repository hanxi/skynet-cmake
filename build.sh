BUILD_DIR=${BUILD_DIR:-build}

mkdir -p "$BUILD_DIR" \
  && cd "$BUILD_DIR" \
  && cmake ..\
  && cmake --build . -j \
  && ./skynet examples/config