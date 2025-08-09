{
  description = "Cursor Agent packaged as a Nix flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }: let
    supportedSystems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
    forAllSystems = f: nixpkgs.lib.genAttrs supportedSystems (system: f system);
  in
  {
    packages = forAllSystems (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          config = { allowUnfree = true; }; # Is this the best solution?
        };

        # Map Nix system to Cursor Agent's OS/ARCH naming
        osArch = {
          "x86_64-linux" = { os = "linux"; arch = "x64"; };
          "aarch64-linux" = { os = "linux"; arch = "arm64"; };
          "x86_64-darwin" = { os = "darwin"; arch = "x64"; };
          "aarch64-darwin" = { os = "darwin"; arch = "arm64"; };
        }."${system}";

        versionHash = "32c684dc5c8a0e364043db77d4e5b9a5dc1e2d3b";

        url = "https://downloads.cursor.com/lab/${versionHash}/${osArch.os}/${osArch.arch}/agent-cli-package.tar.gz";
      in
      pkgs.stdenv.mkDerivation {
        pname = "cursor-agent";
        version = versionHash;

        src = pkgs.fetchurl {
          url = url;
          sha256 = "1rzzpka1r4mdcy0rs08k8hiy42q4h24mhvcqb8zm5962hs6q8l4v";
        };

        nativeBuildInputs = [ pkgs.autoPatchelfHook pkgs.makeWrapper ];

        unpackPhase = ''
          mkdir source
          tar --strip-components=1 -xzf $src -C source
        '';

        installPhase = ''
          mkdir -p $out/bin
          cp -r source/* $out/
          # If cursor-agent is inside $out, link it to bin
          if [ -f "$out/cursor-agent" ]; then
            ln -s ../cursor-agent $out/bin/cursor-agent
          elif [ -f "$out/bin/cursor-agent" ]; then
            true
          else
            ln -s $out/$(find . -type f -name cursor-agent | head -n1) $out/bin/cursor-agent
          fi
        '';

        meta = with pkgs.lib; {
          description = "Cursor Agent CLI";
          homepage = "https://cursor.com";
          platforms = supportedSystems;
          license = licenses.unfree;
        };
      }
    );

    defaultPackage = forAllSystems (system: self.packages.${system});
  };
}
