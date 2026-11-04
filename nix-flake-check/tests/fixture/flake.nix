{
  description = "Two red checks and a green one, for nix-flake-check to name.";
  outputs = { self }:
    let
      check = name: script: builtins.derivation {
        inherit name;
        system = "x86_64-linux";
        builder = "/bin/sh";
        args = [ "-c" script ];
      };
      noise = "i=0; while [ $i -lt 80 ]; do echo noise line $i; i=$((i+1)); done";
    in {
      checks.x86_64-linux = {
        buried = check "buried" "echo FAIL row.buried@walker; ${noise}; exit 1";
        second = check "second" "echo 'test tests::second ... FAILED'; ${noise}; exit 1";
        fine = check "fine" "echo fine > $out";
      };
    };
}
