
{
  description = "Cursor CLI Agent";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs }: let
    systems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
    forAllSystems = f: nixpkgs.lib.genAttrs systems (system: f system);

    versionHash = "32c684dc5c8a0e364043db77d4e5b9a5dc1e2d3b";
    osArch = {
      "x86_64-linux" = { os = "linux"; arch = "x64"; };
      "aarch64-linux" = { os = "linux"; arch = "arm64"; };
      "x86_64-darwin" = { os = "darwin"; arch = "x64"; };
      "aarch64-darwin" = { os = "darwin"; arch = "arm64"; };
    };
  in {
    packages = forAllSystems (system:
      let
        pkgs = import nixpkgs { inherit system; };
        url = "https://downloads.cursor.com/lab/${versionHash}/${osArch.${system}.os}/${osArch.${system}.arch}/agent-cli-package.tar.gz";
      in
      pkgs.stdenv.mkDerivation {
        pname = "cursor-agent";
        version = versionHash;

        src = pkgs.runCommand "fetch-cursor-agent" { buildInputs = [ pkgs.curl ]; } ''
          mkdir -p $out
          curl -L ${url} -o $out/agent-cli-package.tar.gz
        '';

        nativeBuildInputs = [ pkgs.autoPatchelfHook pkgs.makeWrapper ];

        unpackPhase = ''
          mkdir source
          tar --strip-components=1 -xzf $src/agent-cli-package.tar.gz -C source
        '';

        installPhase = ''
          mkdir -p $out/bin
          cp -r source/* $out/
          if [ -f "$out/cursor-agent" ]; then
            ln -s ../cursor-agent $out/bin/cursor-agent
          elif [ -f "$out/bin/cursor-agent" ]; then
            true
          else
            ln -s $out/$(find $out -type f -name cursor-agent | head -n1) $out/bin/cursor-agent
          fi
        '';

        meta = with pkgs.lib; {
          description = "Cursor Agent CLI";
          homepage = "https://cursor.com";
          platforms = systems;
          license = licenses.unfree;
        };
      }
    );

    defaultPackage = forAllSystems (system: self.packages.${system});
  }
}
