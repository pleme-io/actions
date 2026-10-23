{
  toolchain ? "stable",
  components ? "",
  targets ? "",
}:
let
  nixpkgs = builtins.getFlake "github:NixOS/nixpkgs/nixos-26.05";
  rustOverlay = builtins.getFlake "github:oxalica/rust-overlay";
  pkgs = import nixpkgs.outPath {
    system = builtins.currentSystem;
    overlays = [ rustOverlay.overlays.default ];
  };
  split = s: builtins.filter (x: x != "") (map (x: pkgs.lib.trim x) (pkgs.lib.splitString "," s));
  channels = {
    stable = pkgs.rust-bin.stable.latest.default;
    beta = pkgs.rust-bin.beta.latest.default;
    nightly = pkgs.rust-bin.selectLatestNightlyWith (t: t.default);
  };
  base =
    if channels ? ${toolchain} then
      channels.${toolchain}
    else if pkgs.rust-bin.stable ? ${toolchain} then
      pkgs.rust-bin.stable.${toolchain}.default
    else
      throw "rust-toolchain: '${toolchain}' is not stable, beta, nightly or an exact stable version such as 1.89.0";
in
base.override {
  extensions = split components;
  targets = split targets;
}
