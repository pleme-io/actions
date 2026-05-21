# Docker image for the derive-version-from-tag action.
#
# Inherits the pre-installed tatara-script binary from the
# pleme-io/tatara-lisp Docker image (built via nix dockerTools and
# published by tatara-lisp's release-binaries.yml). All this image
# does is bake in the action's run.tlisp so the ENTRYPOINT can exec
# tatara-script on it without any shell intermediate.
#
# Why pin a version rather than `:latest`? Reproducibility — a
# composite-action run a year from now should land on the same lisp
# interpreter unless we explicitly upgrade. The version is bumped in
# lockstep with tatara-lisp releases.

FROM ghcr.io/pleme-io/tatara-script:v0.2.0

COPY run.tlisp /run.tlisp

ENTRYPOINT ["tatara-script", "/run.tlisp"]
