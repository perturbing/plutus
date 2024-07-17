{ repoRoot, inputs, pkgs, system, lib }:

let
  extractDocs = xs: map (x: x.doc) (lib.filter (x: x ? doc) xs);

  cleanFlattenAttrs = s: lib.attrValues (removeAttrs s [ "recurseForDerivations" ]);

  collectComponents = group:
    pkgs.haskell-nix.haskellLib.collectComponents' group (
      pkgs.haskell-nix.haskellLib.selectProjectPackages repoRoot.nix.project.cabalProject.hsPkgs
    );

  plutus-libs = cleanFlattenAttrs (collectComponents "library");

  plutus-internal-libs =
    lib.concatMap cleanFlattenAttrs (
      cleanFlattenAttrs (collectComponents "sublibs")
    );

  haddock-libs = pkgs.symlinkJoin {
    name = "haddock-paths";
    paths = extractDocs plutus-libs;
  };

  haddock-internal-libs = pkgs.symlinkJoin {
    name = "haddock-paths";
    paths = extractDocs plutus-internal-libs;
  };

  combined-haddock = pkgs.runCommand "combine-haddock" { } ''
    mkdir -p $out
    cp -R ${haddock-libs}/share/doc/. $out

    echo "Collecting --read-interface options"
    INTERFACE_OPTIONS=()
    for haddock_file in $(find $out -name "*.haddock"); do
      package=$(basename -s .haddock "$haddock_file")
      INTERFACE_OPTIONS+=("--read-interface=$package,$haddock_file")
    done

    echo "Generating top-level index and contents"
    ${repoRoot.nix.project.cabalProject.pkg-set.config.ghc.package}/bin/haddock \
      -o $out \
      --title "Combined Plutus Documentation" \
      --gen-index \
      --gen-contents \
      --quickjump \
      "''${INTERFACE_OPTIONS[@]}"
  '';

in

{
  inherit combined-haddock haddock-libs haddock-internal-libs;
}


