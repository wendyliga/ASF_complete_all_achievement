FROM swift:5.5

WORKDIR /app

# build everything with optimizations
RUN swift build -c release

# copy the executable to the /app directory
RUN cp "$(swift build --package-path .build -c release --show-bin-path)/" /app