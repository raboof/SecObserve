{ pkgs ? import <nixpkgs> {} }:

# Run via flake or standalone with 'nix-shell ./run.nix -A env'

let
  pkg = pkgs.callPackage ./package.nix {};
  runtime_env = {
    API_BASE_URL = "http://localhost:5000/api";
    OIDC_ENABLE = "false";
    OIDC_AUTHORITY = "dummy";
    OIDC_CLIENT_ID = "dummy";
    OIDC_REDIRECT_URI = "http://localhost:3000";
  };
  runtime_env_js = pkgs.writeText "runtime-env.js" ''
    window.__RUNTIME_CONFIG__ = ${builtins.toJSON runtime_env}
  '';
in
  pkgs.buildFHSEnv {
    name = "start";
    targetPkgs = pkgs: [
      pkg
      pkgs.nginx
    ];
    extraBuildCommands = ''
      mkdir -p $out/usr/share/nginx/html
      cd ${pkg}/html
      for i in * ; do ln -s ${pkg}/html/$i $out/usr/share/nginx/html/$i ; done
      ln -s ${runtime_env_js} $out/usr/share/nginx/html/runtime-env.js
    '';
    extraBwrapArgs = [
      "--tmpfs /var/log/nginx"
    ];
    passthru.npm = pkg;
    runScript = ''
      nginx -g "daemon off;" -c /etc/nginx/nginx.conf
      echo nginx -g \"daemon off\;\" -c /etc/nginx/nginx.conf
      echo ${pkg}
      bash
    '';
  }
