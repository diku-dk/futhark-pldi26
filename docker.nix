{ pkgs ? import (fetchTarball
  "https://github.com/NixOS/nixpkgs/archive/0f1874526206d8a2d6f0a3925618cc45ac83049f.tar.gz")
  { } }:
let
  futhark-PropPropArchive = import ./artifact/futhark-PropProp/default.nix { };
  futhark-PropProp = futhark-PropPropArchive.overrideAttrs (old: {
    installPhase = ''
      mkdir -p $out/bin
      tar xf futhark-nightly.tar.xz
      cp futhark-nightly/bin/futhark $out/bin/futhark-PropProp
      ln -s $out/bin/futhark-PropProp $out/bin/futhark
    '';
  });

  artifact = pkgs.runCommand "container-artifact-dir" {} ''
    cp -r ${./artifact} $out/artifact
  '';

  cuda = pkgs.dockerTools.pullImage {
    imageName = "nvidia/cuda";
    imageDigest = "sha256:520292dbb4f755fd360766059e62956e9379485d9e073bbd2f6e3c20c270ed66";
    sha256 = "sha256-eMo1+SfCjMh2zwXvfagw0v8QppUBdcJdhAct0f8MKlY=";
    finalImageName = "nvidia/cuda";
    finalImageTag = "12.8.1-devel-ubuntu24.04";
  };

  imageEnv = pkgs.buildEnv {
    name = "image-env";
    paths = with pkgs; [
      futhark-PropProp
      bashInteractive
      dafny
      janet
      python3

      # Dependencies
      glibc
      coreutils
      gnugrep
      gnused
      gnumake
      findutils
      less
      nano
      which
      vim
    ];
  };

in pkgs.dockerTools.buildImage {
  name = "propprop";
  tag = "latest";
  created = "now";
  fromImage = cuda;

  copyToRoot = artifact;

  config = {
    Env = [
      "PATH=${imageEnv}/bin:/usr/local/nvidia/bin:/usr/local/cuda/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
      "XDG_CACHE_HOME=/tmp"
      "CPATH=/usr/local/cuda/include"
      "C_INCLUDE_PATH=/usr/local/cuda/include"
      "CPLUS_INCLUDE_PATH=/usr/local/cuda/include"
      "LIBRARY_PATH=/usr/local/cuda/lib64:/usr/local/cuda/lib64/stubs"
      "LD_LIBRARY_PATH=/usr/local/cuda/lib64:/usr/local/cuda/lib64/stubs:/usr/local/nvidia/lib:/usr/local/nvidia/lib64"
    ];
    Cmd = [ "${pkgs.bashInteractive}/bin/bash" "--login" ];
    WorkingDir = "/artifact";
  };
}
