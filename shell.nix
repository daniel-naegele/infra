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
    k9s
    kubernetes-helm
    kube-capacity
    kubectl-view-secret
    velero

    # Secure Boot signing tools
    p7zip
    sbsigntool
    xorriso
  ];

  shellHook = ''

  '';
}
