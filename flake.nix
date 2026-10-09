{
  description = "Official postgraduate 201 papers, typeset with Typix";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    typix = {
      url = "github:loqusion/typix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nur-fonts = {
      url = "github:DzmingLi/nur-packages";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, typix, nur-fonts }:
    let
      systems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
      forAllSystems = nixpkgs.lib.genAttrs systems;
      buildFor = system:
        let
          pkgs = import nixpkgs { inherit system; config.allowUnfree = true; };
          lib = pkgs.lib;
          typixLib = typix.mkLib pkgs;
          founderFonts = pkgs.callPackage (nur-fonts + "/pkgs/fangzheng-fonts") { };
          windowsFonts = pkgs.callPackage (nur-fonts + "/pkgs/windows-fonts") { };
          fontPaths = [ "${founderFonts}/share/fonts/truetype" "${windowsFonts}/share/fonts/truetype" ];
          typstPackages = import ./typst-packages.nix;
          pdfPython = pkgs.python3.withPackages (p: [ p.pypdf ]);
          src = builtins.path {
            path = ./.;
            name = "kaoyan-201-sources";
            filter = path: type:
              let
                relative = lib.removePrefix (toString ./. + "/") (toString path);
                parts = lib.splitString "/" relative;
                allowedRoots = [ "题型示例" "scripts" "template.typ" "词汇表.org" "国家与地区.org" "大洲与大洋.org" "一般评分标准.org" ];
                allowed = lib.elem (lib.head parts) allowedRoots || builtins.match "20[0-9][0-9]" (lib.head parts) != null;
                excluded = lib.any (part: lib.elem part [ "preview" "backups" ".build" ".git" "output" ]) parts;
              in
              !excluded && allowed &&
              (type == "directory" || lib.any (ext: lib.hasSuffix ext relative) [ ".typ" ".org" ".py" ".svg" ".png" ".jpg" ".jpeg" ".json" ".toml" ]);
          };
          pdfs = typixLib.mkTypstDerivation {
            name = "kaoyan-201-official-pdfs";
            inherit src fontPaths;
            emojiFont = null;
            unstable_typstPackages = typstPackages;
            nativeBuildInputs = [ pdfPython ];
            buildPhaseTypstCommand = ''
              python3 scripts/org-preview.py
              python3 scripts/test-booklet.py
              python3 scripts/build-pdfs.py --output "$out" --jobs 4
            '';
            installPhaseCommand = "true";
          };
        in {
          packages = { default = pdfs; inherit pdfs; fonts = founderFonts; windows-fonts = windowsFonts; };
          checks = { inherit pdfs; };
          devShell = typixLib.devShell {
            inherit fontPaths;
            emojiFont = null;
            TYPST_PACKAGE_CACHE_PATH = typixLib.fetchTypstPackages typstPackages;
            packages = [ pdfPython pkgs.gh ];
          };
        };
    in {
      packages = forAllSystems (system: (buildFor system).packages);
      checks = forAllSystems (system: (buildFor system).checks);
      devShells = forAllSystems (system: { default = (buildFor system).devShell; });
    };
}
