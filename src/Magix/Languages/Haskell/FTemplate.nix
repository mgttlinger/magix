{
  inputs = {
    nixpkgs.url = "nixpkgs";
    __FLAKES__
  };
  outputs = inputs@{ self, nixpkgs, ... }:
    let
      system = "aarch64-darwin";
      overlay = selfn: supern: {
        haskell = supern.haskell // {
          packageOverrides =
            selfh: superh:
            supern.haskell.packageOverrides selfh superh
            // {
              __OVERRIDES__
            };
        };
      };
      pkgs = nixpkgs.legacyPackages.${system}.extend overlay;
    in
    {
      packages.${system}.default = pkgs.stdenv.mkDerivation {
        name = "__SCRIPT_NAME__";

        src = builtins.path { path = __SCRIPT_SOURCE__; };
        dontUnpack = true;

        nativeBuildInputs = with pkgs; [ makeWrapper ];

        buildInputs = with pkgs; [
          (haskellPackages.ghcWithPackages (ps: with ps; [ __HASKELL_PACKAGES__ ]))
        ];

        buildPhase = ''
          mkdir bin

          script_source_hs="__SCRIPT_NAME__.hs"
          ln -s "$src" "$script_source_hs"
          ghc __GHC_FLAGS__ -o "bin/__SCRIPT_NAME__" "$script_source_hs"
        '';

        installPhase = ''
          mkdir -p $out
          mv bin $out/

          wrapProgram "$out/bin/__SCRIPT_NAME__"
        '';
      };
    };
}
