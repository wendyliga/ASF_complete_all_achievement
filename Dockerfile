FROM swift:5.5-focal as builder
WORKDIR /app
COPY . .
RUN mkdir -p /build/lib && cp -R /usr/lib/swift/linux/*.so* /build/lib
RUN swift build -c release && mv `swift build -c release --show-bin-path` /build/bin

FROM swift:5.5-focal-slim
VOLUME /app/config.json
LABEL maintainer="me@wendyliga.com"
WORKDIR /app
COPY --from=builder /build/bin/wrangler .
CMD [ "./wrangler" ]