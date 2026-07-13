{
  lib,
  stdenv,
  fetchFromGitHub,
  kernel,
  utilLinux,
  usbModeswitch,
}:

stdenv.mkDerivation rec {
  pname = "aic8800d80";
  version = "unstable-2026-06-25";

  src = fetchFromGitHub {
    owner = "shenmintao";
    repo = "aic8800d80";
    rev = "3f9916b6ff63131918712a4b883a1d6dd98804ce";
    hash = "sha256-uRHafdxDqJm7kV6lvWQurVNNRBXz5yrB9AXwEDfik7I=";
  };

  nativeBuildInputs = kernel.moduleBuildDependencies;

  makeFlags = [
    "KVER=${kernel.modDirVersion}"
    "KDIR=${kernel.dev}/lib/modules/${kernel.modDirVersion}/build"
  ];

  postPatch = ''
    substituteInPlace aic.rules \
      --replace-fail /usr/bin/eject ${utilLinux}/bin/eject
  '';

  buildPhase = ''
    runHook preBuild
    make -C drivers/aic8800 \
      KVER=${kernel.modDirVersion} \
      KDIR=${kernel.dev}/lib/modules/${kernel.modDirVersion}/build
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    modDir=$out/lib/modules/${kernel.modDirVersion}/kernel/drivers/net/wireless/aic8800
    mkdir -p "$modDir"
    install -Dm644 drivers/aic8800/aic8800_fdrv/aic8800_fdrv.ko "$modDir/aic8800_fdrv.ko"
    install -Dm644 drivers/aic8800/aic_load_fw/aic_load_fw.ko "$modDir/aic_load_fw.ko"

    mkdir -p $out/lib/firmware
    cp -r fw/* $out/lib/firmware/

    install -Dm644 aic.rules $out/lib/udev/rules.d/90-aic8800-mode-switch.rules
    install -Dm644 usb_modeswitch/1111_1111 $out/etc/usb_modeswitch.d/1111:1111

    runHook postInstall
  '';

  meta = {
    description = "Out-of-tree kernel driver and firmware for AIC8800D80 USB Wi-Fi/Bluetooth adapters";
    homepage = "https://github.com/shenmintao/aic8800d80";
    license = with lib.licenses; [
      gpl2Only
      asl20
      unfreeRedistributableFirmware
    ];
    sourceProvenance = with lib.sourceTypes; [
      fromSource
      binaryFirmware
    ];
    platforms = lib.platforms.linux;
  };
}
