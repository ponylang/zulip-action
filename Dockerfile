FROM ghcr.io/ponylang/shared-docker-ci-standard-builder-with-libressl-4.2.0:release AS build

WORKDIR /src
COPY . .

RUN make build-action ssl=libressl static=true config=release

FROM alpine:3.21

RUN apk add --no-cache ca-certificates

COPY --from=build /src/build/release/action /zulip_action

ENTRYPOINT ["/zulip_action"]
