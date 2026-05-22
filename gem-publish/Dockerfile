# Dockerfile for gem-publish action — pure FROM + COPY + ENTRYPOINT.
# Ruby is baked into the tatara-script base image (v0.3.0+) so this
# Dockerfile carries zero RUN steps.

FROM ghcr.io/pleme-io/tatara-script:v0.3.0

COPY run.tlisp /run.tlisp

ENTRYPOINT ["tatara-script", "/run.tlisp"]
