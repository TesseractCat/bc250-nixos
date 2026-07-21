{
  lib,
  stdenv,
  fetchFromGitHub,
}:

stdenv.mkDerivation rec {
  pname = "bc250-memcfg";
  version = "unstable-2026-05-22";

  src = fetchFromGitHub {
    owner = "fanoush";
    repo = "bc250_memcfg";
    rev = "829e8d64f23c5ad1e1d662f4eab488f31e0daa72";
    hash = "sha256-5qOz1b7Rx18Xjg/cLYU6XTVpG0Fcmz9ezCsO59vAyNg=";
  };

  buildPhase = ''
    runHook preBuild

    $CXX -Os main.cpp -o bc250memcfg

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    install -Dm755 bc250memcfg "$out/bin/bc250memcfg"

    runHook postInstall
  '';

  meta = {
    description = "BC-250 tool to set CMOS BIOS memory configuration from Linux";
    homepage = "https://github.com/fanoush/bc250_memcfg";
    sourceProvenance = with lib.sourceTypes; [ fromSource ];
    platforms = lib.platforms.linux;
    mainProgram = "bc250memcfg";
  };
}
