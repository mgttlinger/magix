{
  pkgs ? import <nixpkgs> { }
}:
let
  overlay = self: super: { haskellPackages = super.haskellPackages.override { overrides = sself: ssuper: { __OVERRIDES__ }; }; };
  magixpkgs = pkgs.extend overlay;
in
magixpkgs.stdenv.mkDerivation {
  name = "__SCRIPT_NAME__";

  src = builtins.path { path = __SCRIPT_SOURCE__; };
  dontUnpack = true;

  nativeBuildInputs = with magixpkgs; [ makeWrapper ];

  buildInputs = with magixpkgs; [
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
}
