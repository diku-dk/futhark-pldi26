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
in pkgs.dockerTools.buildImage {
  name = "607";
  tag = "latest";
  created = "now";
  copyToRoot = pkgs.buildEnv {
    name = "image-root";
    paths = with pkgs; [
      futhark-PropProp

      # Dependencies
      coreutils
      gnugrep
      gnused
      gnumake
      gawk
      bash
      findutils
      fontconfig
      less
      nano
      scc
      hyperfine
      gnuplot
      bc
    ];
  };

  runAsRoot = ''
    mkdir -p /tmp
    chmod 777 /tmp

    mkdir /.cache
    chmod 777 /.cache
    export XDG_CACHE_HOME=/.cache

    mkdir -p /.cache/fonts
    chmod 777 /.cache/fonts

    mkdir -p /etc/fonts
    chmod 777 /etc/fonts
    cp -r ${pkgs.fontconfig.out}/etc/fonts/* /etc/fonts/
    export FONTCONFIG_PATH=/etc/fonts

    fc-cache -fv
  '';

  config = {
    Cmd = [ "/bin/bash" ];
    WorkingDir = "${artifact}";
  };

}
