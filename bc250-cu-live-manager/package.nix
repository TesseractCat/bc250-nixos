{
  lib,
  stdenvNoCC,
  fetchFromGitHub,
  makeWrapper,
  bash,
  coreutils,
  gawk,
  gnugrep,
  gnused,
  libdrm,
  pciutils,
  python3,
  systemd,
  umr,
}:

stdenvNoCC.mkDerivation rec {
  pname = "bc250-cu-live-manager";
  version = "unstable-2026-06-08";

  src = fetchFromGitHub {
    owner = "WinnieLV";
    repo = "bc250-cu-live-manager";
    rev = "8eb45f07810af738f3e4945ea0cc29d399e378a6";
    hash = "sha256-x//BTB7CdqZyoR4+Hjr3bZcmLk20SCE/9txhGBDUnuE=";
  };

  nativeBuildInputs = [ makeWrapper ];

  installPhase = ''
    runHook preInstall

    install -Dm755 bc250-cu-live-manager.sh \
      "$out/bin/bc250-cu-live-manager"

    patchShebangs "$out/bin/bc250-cu-live-manager"

    substituteInPlace "$out/bin/bc250-cu-live-manager" \
      --replace-fail 'for p in /usr/bin/umr /usr/local/bin/umr /opt/umr/build/src/app/umr; do' \
        'for p in ${lib.getExe' umr "umr"} /usr/bin/umr /usr/local/bin/umr /opt/umr/build/src/app/umr; do' \
      --replace-fail '/usr/bin/bash' '${lib.getExe bash}'

    wrapProgram "$out/bin/bc250-cu-live-manager" \
      --prefix PATH : ${lib.makeBinPath [
        bash
        coreutils
        gawk
        gnugrep
        gnused
        pciutils
        python3
        systemd
        umr
      ]} \
      --prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath [ libdrm ]}

    runHook postInstall
  '';

  meta = {
    description = "Interactive BC-250 CU/WGP live manager using UMR, with TUI controls, safety checks, and boot-table persistence";
    homepage = "https://github.com/WinnieLV/bc250-cu-live-manager";
    sourceProvenance = with lib.sourceTypes; [ fromSource ];
    platforms = lib.platforms.linux;
    mainProgram = "bc250-cu-live-manager";
  };
}
