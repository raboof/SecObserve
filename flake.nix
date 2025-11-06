{
  description = "SecObserver";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    poetry2nix = {
      #url = "github:nix-community/poetry2nix";
      # various fixes that perhaps should be contributed or moved
      # to overrides
      url = "github:raboof/poetry2nix?ref=cf9c89613fddfd1d79fbc3b5cd1617e33e5169fb";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, poetry2nix }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
      pn = poetry2nix.lib.mkPoetry2Nix { inherit pkgs; };
    in
    {
      packages.${system} =
        let
          backend = pkgs.callPackage ./backend.nix { poetry2nix = pn; };
        in
        {
          frontend = pkgs.callPackage ./frontend/run.nix {};
          backend = backend;
          manage = backend.overrideAttrs {
            meta.mainProgram = "manage.py";
          };
        };
    };
}
