{
  description = "SecObserver";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    poetry2nix = {
      #url = "github:nix-community/poetry2nix";
      # various fixes
      url = "github:raboof/poetry2nix?ref=95762fc690051726b9dceb1d7de75617b1d27fa9";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    secobserve-src = {
      url = "github:MaibornWolff/SecObserve?ref=v1.38.0";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, poetry2nix, secobserve-src }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
      pn = poetry2nix.lib.mkPoetry2Nix { inherit pkgs; };
    in
    {
      packages.${system} = {
        frontend = pkgs.callPackage ./frontend.nix {};
        backend = pkgs.callPackage ./backend.nix { poetry2nix = pn; };
      };
    };
}
