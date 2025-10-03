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
      inherit (pn) mkPoetryApplication;
    in
    {
      packages.${system} = {
        frontend = pkgs.callPackage ./frontend.nix {};
        backend =
        let
          projectDir = pkgs.runCommand "secobserve-backend-src" {} ''
            mkdir -p $out
            cd ${secobserve-src}/backend
            for i in *; do ln -s ${secobserve-src}/backend/$i $out/$i; done
            cd $out
            rm pyproject.toml
            cp ${secobserve-src}/backend/pyproject.toml .
            patch < ${./backend-pep517.patch}
          '';
        in
        mkPoetryApplication {
          inherit projectDir;
          overrides = pn.overrides.withDefaults(final: prev: {
            psycopg-binary = prev.psycopg2-binary;
            black = null;
            nh3 = prev.nh3.overridePythonAttrs
            (old: {
              nativeBuildInputs = old.nativeBuildInputs or [ ] ++ [ pkgs.maturin pkgs.rustPlatform.cargoSetupHook pkgs.rustPlatform.maturinBuildHook ];
              cargoDeps = pkgs.rustPlatform.fetchCargoVendor {
                src = prev.nh3.src;
                hash = "sha256-+95jR9XQfaVxV5OYc8wyZIq94QOz63gG5vs7TIkbDjc=";
              };
            });
            pydantic-core = null;
          });
          buildPhase = ''
            runHook preBuild
            mkdir dist
            runHook postBuild
          '';
          installPhase =
            let
              manage = pkgs.writeScript "manage.sh" ''
                #!/usr/bin/env sh
                export PYTHONPATH=subst_pythonpath
                cd subst_appdir

                # TODO move elsewhere
                export DJANGO_SECRET_KEY=42
                export ALLOWED_HOSTS=localhost
                export DATABASE_ENGINE=django.db.backends.postgresql
                export DATABASE_HOST=/run/postgresql/
                export DATABASE_PORT=
                export DATABASE_DB=secobserve
                export DATABASE_USER=aengelen
                export DATABASE_PASSWORD=
                export CORS_ALLOWED_ORIGINS=http://localhost:3000
                export FIELD_ENCRYPTION_KEY=kGZfYHqY6iAxKnX6q5WJmtFz7T5A40E8dREc1Ywaz0w=

                export HUEY_FILENAME=/tmp/huey.db

                ${pkgs.python3}/bin/python3 manage.py $@
              '';
              entrypoint = pkgs.writeScript "secobserve-backend.sh" ''
                #!/usr/bin/env sh
                export PYTHONPATH=subst_pythonpath
                cd subst_appdir

                # TODO move elsewhere
                export DJANGO_SECRET_KEY=42
                export ALLOWED_HOSTS=localhost
                export DATABASE_ENGINE=django.db.backends.postgresql
                export DATABASE_HOST=/run/postgresql/
                export DATABASE_PORT=
                export DATABASE_DB=secobserve
                export DATABASE_USER=aengelen
                export DATABASE_PASSWORD=
                export CORS_ALLOWED_ORIGINS=http://localhost:3000
                export FIELD_ENCRYPTION_KEY=kGZfYHqY6iAxKnX6q5WJmtFz7T5A40E8dREc1Ywaz0w=

                export HUEY_FILENAME=/tmp/huey.db

                ${pkgs.python3Packages.gunicorn}/bin/gunicorn config.wsgi --bind 127.0.0.1:5000
              '';
            in
          ''
            mkdir -p $out/app
            cp -r * $out/app

            mkdir -p $out/bin
            cp ${entrypoint} $out/bin/secobserve
            substituteInPlace $out/bin/secobserve \
              --replace-fail "subst_pythonpath" "$PYTHONPATH" \
              --replace-fail "subst_appdir" "$out/app"

            cp ${manage} $out/bin/manage.py
            substituteInPlace $out/bin/manage.py \
              --replace-fail "subst_pythonpath" "$PYTHONPATH" \
              --replace-fail "subst_appdir" "$out/app"
          '';
        };
      };
    };
}
