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

buildNpmPackage (finalAttrs: {
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
})
