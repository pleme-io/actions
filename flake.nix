{
  description = "pleme-io/actions — Docker action images built via nix dockerTools, published to ghcr.io alongside per-action action.yml manifests.";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    # Tatara-script base image (universal pleme-io action layer:
    # tatara-script + git + curl + ruby + helm + skopeo + coreutils,
    # /tmp + /var/tmp pre-created, runs as root for $GITHUB_OUTPUT).
    tatara-lisp = {
      url = "github:pleme-io/tatara-lisp";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, flake-utils, tatara-lisp }:
    flake-utils.lib.eachSystem [ "x86_64-linux" "aarch64-linux" ] (system: let
      pkgs = import nixpkgs { inherit system; };
      baseImage = tatara-lisp.packages.${system}.image;

      # mkActionImage — one composite image per action.
      # Inherits the universal tatara-script base, layers in the
      # action's run.tlisp, sets the entrypoint to execute it.
      # Published name: ghcr.io/pleme-io/action-<name>:<tag>.
      mkActionImage = { name }: pkgs.dockerTools.buildLayeredImage {
        name = "ghcr.io/pleme-io/action-${name}";
        tag = "latest";
        fromImage = baseImage;
        contents = [ ];
        extraCommands = ''
          cp ${./. + "/${name}/run.tlisp"} run.tlisp
        '';
        config = {
          Entrypoint = [ "tatara-script" "/run.tlisp" ];
          # All inputs are forwarded via env: in each action.yml's
          # runs: block (clean POSIX names — INPUT_<NAME> dashes
          # don't round-trip), so no Cmd or args needed here.
          WorkingDir = "/github/workspace";
        };
      };

      # Every action whose run.tlisp lives at ./<name>/run.tlisp gets
      # an image. Add new actions here; the publish workflow loops over
      # this list.
      tlispActions = [
        "derive-version-from-tag"
        "gem-publish"
        "git-push-with-token"
        "helm-oci-publish"
        "oci-image-push"
      ];

      imagePackages = nixpkgs.lib.listToAttrs (map (n: {
        name = "${n}-image";
        value = mkActionImage { name = n; };
      }) tlispActions);
    in {
      packages = imagePackages // {
        # Default to the derive-version-from-tag image as a smoke target
        # for `nix build` without args.
        default = imagePackages."derive-version-from-tag-image";
      };

      # Expose the action list so the publish workflow can enumerate.
      apps.list-action-images = {
        type = "app";
        program = toString (pkgs.writeShellScript "list-action-images" ''
          ${pkgs.lib.concatMapStringsSep "\n"
            (n: "echo ${n}")
            tlispActions}
        '');
      };
    });
}
