{
  description = "NextJS Template";

  inputs = {
    nixpkgs.url = "nixpkgs";
    systems.url = "github:nix-systems/x86_64-linux";
    flake-utils = {
      url = "github:numtide/flake-utils";
      inputs.systems.follows = "systems";
    };
  };

  outputs =
    { nixpkgs
    , flake-utils
    , ...
    }:
    flake-utils.lib.eachDefaultSystem (system:
    let
      pkgs = nixpkgs.legacyPackages.${system};
      pname = ""; # <same as package.json name>
      version = "0.1.0";
      buildInputs = with pkgs; [
        nodejs_20
        nodePackages_latest.pnpm
        pre-commit
      ];
      nativeBuildInputs = buildInputs;
      devPkgs = with pkgs; [
        pre-commit
        just
      ];
      npmDepsHash = ""; # <prefetch-npm-deps package-lock.json>
    in
    {
      devShells.default = pkgs.mkShell {
        inherit buildInputs;
        packages = devPkgs;
        shellHook = ''
          #!/usr/bin/env bash
          if ! grep -q "pre-commit" .git/hooks/pre-commit 2>/dev/null; then
              pre-commit install
          fi
        '';
      };
      packages.default = pkgs.buildNpmPackage {
        inherit pname version buildInputs npmDepsHash nativeBuildInputs;
        src = ./.;
        postInstall = ''
          mkdir -p $out/bin
          exe="$out/bin/${pname}"
          lib="$out/lib/node_modules/${pname}"
          cp -r ./.next $lib
          touch $exe
          chmod +x $exe
          echo "
              #!/usr/bin/env bash
              cd $lib
              ${pkgs.nodePackages_latest.pnpm}/bin/pnpm run start" > $exe
        '';
      };
    });
}
