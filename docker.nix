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
  artifact = pkgs.copyPathToStore ./artifact;

  cuda = pkgs.dockerTools.pullImage {
    imageName = "nvidia/cuda";
    imageDigest = "sha256:c2621d98e7de80c2aec5eb8403b19c67454c8f5b0c929e8588fd3563c9b6558d";
    sha256 = "sha256-eVMmE1AAPQb/wi1/JHBrXAITup7IKXKfRP9C3fBJkLI=";
    finalImageName = "nvidia/cuda";
    finalImageTag = "13.0.0-devel-ubuntu24.04";
  };

in pkgs.dockerTools.buildLayeredImage {
  name = "propprop";
  tag = "latest";
  created = "now";
  fromImage = cuda;

  contents = with pkgs; [
    futhark-PropProp
    bashInteractive

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
    dafny
  ];

  extraCommands = ''
    mkdir -p /tmp
    chmod 777 /tmp

    mkdir -p /.cache
    chmod 777 /.cache

    mkdir -p /lib/x86_64-linux-gnu
    ln -s /usr/lib/x86_64-linux-gnu/* /lib/x86_64-linux-gnu/

    cat > /etc/profile.d/propprop.sh << 'EOF'
export XDG_CACHE_HOME=/.cache
export CPATH="/usr/local/cuda/include:$CPATH"
export C_INCLUDE_PATH="/usr/local/cuda/include:$C_INCLUDE_PATH"
export CPLUS_INCLUDE_PATH="/usr/local/cuda/include:$CPLUS_INCLUDE_PATH"
export LIBRARY_PATH="/usr/local/cuda/lib64:/usr/local/cuda/lib64/stubs:$LIBRARY_PATH"
export LD_LIBRARY_PATH="/usr/local/cuda/lib64:/usr/local/cuda/lib64/stubs:$LD_LIBRARY_PATH"
EOF
  '';

  config = {
    Cmd = [ "${pkgs.bashInteractive}/bin/bash" "--login"];
    WorkingDir = "${artifact}";
  };

}
