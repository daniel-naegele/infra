{
  pkgs ? import <nixpkgs> { },
  ...
}:
with pkgs;
mkShell {
  packages = [
    flux
    kubectl
    kubectx
    sops
    age
    headscale
    yq
    kubernetes-helm
    kube-capacity
    kubectl-view-secret
    velero
  ];

  shellHook = ''

  '';
}
