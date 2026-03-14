{ pkgs ? import (fetchTarball
  "https://github.com/NixOS/nixpkgs/archive/0f1874526206d8a2d6f0a3925618cc45ac83049f.tar.gz")
  { } }:
let
  futhark-PropProp0 = import ./artifact/futhark-PropProp/default.nix { };
  futhark-PropProp = futhark-PropProp0.overrideAttrs (old: {
    installPhase = ''
      mkdir -p $out/bin
      tar xf futhark-nightly.tar.xz
      cp futhark-nightly/bin/futhark $out/bin/futhark-PropProp
    '';
  });
  artifact = pkgs.copyPathToStore ./artifact;

  cuda = pkgs.dockerTools.pullImage {
    imageName = "nvidia/cuda";
    imageDigest = "sha256:9cf8694a27722418a1f175d90f85d5afb5a728fd4a9907d7f0565efecfa14d32";
    sha256 = "sha256-syFX6qHQU6u3bksMF6kcw7kqIJDP5BuEQBSa4QwwNyE=";
    finalImageName = "nvidia/cuda";
    finalImageTag = "13.1.1-devel-ubuntu24.04";
  };

in pkgs.dockerTools.buildImage {
  name = "PropProp";
  tag = "latest";
  created = "now";
  fromImage = cuda;
  copyToRoot = pkgs.buildEnv {
    name = "image-root";
    paths = with pkgs; [
      futhark-PropProp
    ];
  };

  runAsRoot = ''
    mkdir -p /tmp
    chmod 777 /tmp

    mkdir /.cache
    chmod 777 /.cache
    export XDG_CACHE_HOME=/.cache
  '';

  config = {
    Cmd = [ "/bin/bash" ];
    WorkingDir = "${artifact}";
    Env = [
      "CPATH=/usr/local/cuda/include"
      "C_INCLUDE_PATH=/usr/local/cuda/include"
      "CPLUS_INCLUDE_PATH=/usr/local/cuda/include"
      "LIBRARY_PATH=/usr/local/cuda/lib64:/usr/local/cuda/lib64/stubs"
      "LD_LIBRARY_PATH=/usr/local/cuda/lib64:/usr/local/cuda/lib64/stubs"
    ];
  };

}
