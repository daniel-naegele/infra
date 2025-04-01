{
  nixpkgs ? import <nixpkgs> { },
}:
with nixpkgs;
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
