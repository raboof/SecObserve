{
  buildFHSEnv,
  buildNpmPackage,
  fetchFromGitHub,
  lib,
  nginx,
  stdenv,
  writeScript,
  writeText,
}:

let
  runtime_env = {
    API_BASE_URL = "http://localhost:5000/api";
    OIDC_ENABLE = "false";
    OIDC_AUTHORITY = "dummy";
    OIDC_CLIENT_ID = "dummy";
    OIDC_REDIRECT_URI = "http://localhost:3000";
  };
  runtime_env_js = writeText "runtime-env.js" ''
    window.__RUNTIME_CONFIG__ = ${builtins.toJSON runtime_env}
  '';
  pkg = buildNpmPackage (finalAttrs: {
    name = "secobserve-frontend";

    src = fetchFromGitHub {
      owner = "MaibornWolff";
      repo = "SecObserve";
      tag = "v1.39.0";
      hash = "sha256-LqBKlwL5d/GyHVppVjXmgi3jhiv+jRU3NXS6D7XKSZk=";
    };
    sourceRoot = "${finalAttrs.src.name}/frontend";
    npmDepsHash = "sha256-sXK1psJYtXjPc0OVvAMulK8LE91V/2fUR7HZ2ETM8Sg=";

    postInstall = ''
      mkdir -p $out/etc/nginx
      cp ${nginx}/conf/mime.types $out/etc/nginx/mime.types
      cp nginx/nginx.conf $out/etc/nginx/nginx.conf

      mkdir -p $out/etc/nginx/conf.d
      cp nginx/default.conf $out/etc/nginx/conf.d/default.conf

      mkdir -p $out/etc/nginx/html
      cp robots.txt $out/etc/nginx/html/robots.txt

      mkdir -p $out/html
      cp -r build/* $out/html

    '';
  });
in
  buildFHSEnv {
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
