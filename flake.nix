{
  description = "Ralph Orchestrator CLI, packaged as a Nix flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    systems.url = "github:nix-systems/default";
  };

  outputs =
    {
      self,
      nixpkgs,
      systems,
      ...
    }:
    let
      forEachSystem = nixpkgs.lib.genAttrs (import systems);
      sources = builtins.fromJSON (builtins.readFile ./sources.json);
    in
    {
      packages = forEachSystem (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          platform =
            sources.platforms.${system}
              or (throw "ralph-cli: unsupported system ${system}");
          ralph-cli = pkgs.stdenv.mkDerivation {
            pname = "ralph-cli";
            version = sources.version;

            src = pkgs.fetchurl {
              url = "https://github.com/mikeyobrien/ralph-orchestrator/releases/download/v${sources.version}/ralph-cli-${platform.name}.tar.xz";
              hash = platform.hash;
            };

            sourceRoot = ".";
            unpackPhase = ''
              ${pkgs.xz}/bin/xz -d < $src | tar xf -
            '';

            installPhase = ''
              mkdir -p $out/bin
              cp ralph-cli-${platform.name}/ralph $out/bin/
            '';

            passthru.updateScript = ./update.sh;

            meta = {
              description = "Ralph Orchestrator CLI";
              homepage = "https://github.com/mikeyobrien/ralph-orchestrator";
              license = pkgs.lib.licenses.mit;
              sourceProvenance = [ pkgs.lib.sourceTypes.binaryNativeCode ];
              mainProgram = "ralph";
              platforms = builtins.attrNames sources.platforms;
            };
          };
        in
        {
          inherit ralph-cli;
          default = ralph-cli;
        }
      );
    };
}
