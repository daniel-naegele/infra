{
  pkgs ? import <nixpkgs> { },
}:
with pkgs;
mkShell {
  buildInputs = [
    flux
    kubectl
    sops
    age
  ];

  shellHook = ''

  '';
}
