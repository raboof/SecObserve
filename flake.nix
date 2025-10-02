{
  description = "SecObserver";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
  };

  outputs = { self, nixpkgs }: {

    packages.x86_64-linux.frontend =
      nixpkgs.legacyPackages.x86_64-linux.callPackage ./frontend.nix {};

  };
}
