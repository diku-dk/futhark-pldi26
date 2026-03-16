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
      ln -s $out/bin/futhark-PropProp $out/bin/futhark
    '';
  });
in futhark-PropProp
