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
    API_BASE_URL = "http://localhost/api";
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
      tag = "v1.38.0";
      hash = "sha256-gIiy/6VSnIExxXtThC2ZQFpMzlNi2CUJjZMs4uCCJuw=";
    };
    sourceRoot = "${finalAttrs.src.name}/frontend";
    npmDepsHash = "sha256-NQx2TwGkZ8W68O3ed6sj1EgN9do3koe1UuV/KtMrd4A=";

    #postBuild = ''
    #  find .
    #'';
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
      #"--ro-bind ${pkg} /usr/share/nginx/html"
      #"--ro-bind ${pkg}/etc/nginx /etc/nginx"
    ];
    passthru.npm = pkg;
    runScript = ''
      #nginx -g "daemon off;" -c /etc/nginx/nginx.conf
      echo nginx -g \"daemon off\;\" -c /etc/nginx/nginx.conf
      echo ${pkg}
      bash
    '';
  }
