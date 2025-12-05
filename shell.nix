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
    headscale
    yq
    helm
    kube-capacity

  ];

  shellHook = ''

  '';
}
