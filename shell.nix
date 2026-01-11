{
  pkgs ? import <nixpkgs> { },
  ...
}:
with pkgs;
mkShell {
  packages = [
    dagger
    flux
    kubectl
    kubectx
    sops
    age
    go
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
