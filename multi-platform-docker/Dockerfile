#
# cunnie/multi-platform-docker
#
# Prints the architecture of the underlying kernel and then exits.
#
# To build:
#
#   docker buildx build -f Dockerfile -t cunnie/multi-platform-docker --platform linux/arm64/v8,linux/amd64 --push .
#
FROM alpine

LABEL org.opencontainers.image.authors="Brian Cunnie <brian.cunnie@gmail.com>"

CMD ["uname", "-m"]
