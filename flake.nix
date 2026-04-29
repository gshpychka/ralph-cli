{
  description = "Ralph Orchestrator CLI, packaged as a Nix flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    systems.url = "github:nix-systems/default";
  };

  outputs =
    {
      nixpkgs,
      systems,
      ...
    }:
    let
      forEachSystem = nixpkgs.lib.genAttrs (import systems);
    in
    {
      packages = forEachSystem (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          platform =
            {
              "aarch64-darwin" = {
                name = "aarch64-apple-darwin";
                hash = "sha256-j5HF34sY80jZ8UigYqWxkM5siz046UEpVEOe3S7r6t8=";
              };
              "x86_64-darwin" = {
                name = "x86_64-apple-darwin";
                hash = "sha256-brPjK2o1Nl4YIJ/5+wJETaaKQcmV8s95HjO4i7OTJxg=";
              };
              "aarch64-linux" = {
                name = "aarch64-unknown-linux-gnu";
                hash = "sha256-GTEdvsZ+BOuX4gw6mhiorlp0zaRC6sBPoCQ8M+6U6vk=";
              };
              "x86_64-linux" = {
                name = "x86_64-unknown-linux-gnu";
                hash = "sha256-YSmIKhBR9li97oWjB73WWE3B1wSmmaZ2zV/IQs5Cf4I=";
              };
            }
            .${system};
          ralph-cli = pkgs.stdenv.mkDerivation rec {
            pname = "ralph-cli";
            version = "2.9.2";

            src = pkgs.fetchurl {
              url = "https://github.com/mikeyobrien/ralph-orchestrator/releases/download/v${version}/ralph-cli-${platform.name}.tar.xz";
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

            meta = {
              description = "Ralph Orchestrator CLI";
              homepage = "https://github.com/mikeyobrien/ralph-orchestrator";
              license = pkgs.lib.licenses.mit;
              sourceProvenance = [ pkgs.lib.sourceTypes.binaryNativeCode ];
              mainProgram = "ralph";
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
