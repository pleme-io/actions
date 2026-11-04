{
  description = "One green check: nix-flake-check installs nothing and names nothing.";
  outputs = { self }: {
    checks.x86_64-linux.fine = builtins.derivation {
      name = "fine";
      system = "x86_64-linux";
      builder = "/bin/sh";
      args = [ "-c" "echo fine > $out" ];
    };
  };
}
