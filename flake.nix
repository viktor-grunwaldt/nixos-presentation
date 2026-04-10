{
  description = "LaTeX Document Demo";
  inputs.flake-utils.url = "github:numtide/flake-utils";
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
    }:
    with flake-utils.lib;
    eachSystem allSystems (
      system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        tex = pkgs.texlive.combine {
          inherit (pkgs.texlive)
            scheme-small
            latex-bin
            latexmk
            beamer
            polski
            listings
            # minted
            ;
        };
      in
      rec {
        devShells.default =
          with pkgs;
          mkShell {
            packages = [
              texlab
              inkscape
              imagemagick
            ];
          };
        packages = {
          document = pkgs.stdenvNoCC.mkDerivation rec {
            name = "latex-beamer-document";
            src = ./.;
            buildInputs = [
              pkgs.coreutils
              tex
              # pkgs.python311Packages.pygments
              # pkgs.which # minted
            ];
            phases = [
              "unpackPhase"
              "buildPhase"
              "installPhase"
            ];
            buildPhase = ''
              export PATH="${pkgs.lib.makeBinPath buildInputs}";
              # Prevent LuaLaTeX from scanning host OS fonts (huge speedup)
              export OSFONTDIR=""

              # Copy the pre-built Nix texlive cache to our writable directory
              export TEXMFVAR=$(mktemp -d)
              cp -a ${tex}/share/texmf-var/* $TEXMFVAR/
              chmod -R u+w $TEXMFVAR

              export TEXMFHOME=.cache
              export SOURCE_DATE_EPOCH=${toString self.lastModified}

              latexmk -interaction=nonstopmode -pdf -lualatex \
                  -pretex="\pdfvariable suppressoptionalinfo 512\relax" \
                  -usepretex \
                  -shell-escape \
                  ${name}.tex
            '';
            installPhase = ''
              mkdir -p $out
              cp ${name}.pdf $out/
            '';
          };
        };
        defaultPackage = packages.document;
      }
    );
}
