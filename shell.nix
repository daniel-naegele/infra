{
  pkgs ? import <nixpkgs> { },
  ...
}:
with pkgs;
mkShell {
  packages = [
    flux
    kubectl
    sops
    age
  ];

  shellHook = ''

  '';
}
