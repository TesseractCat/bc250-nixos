{
  lib,
  stdenv,
  fetchFromGitHub,
  kernel,
  kernelModuleMakeFlags ? lib.filter (flag: !(lib.hasPrefix "O=" flag)) kernel.makeFlags,
  utilLinux,
  usbModeswitch,
  variant ? "main",
}:

let
  sources = {
    main = {
      date = "2026-10-23";
      rev = "f9ab41822373efe70649d011edb587d1170364e7";
      hash = "sha256-FkIW3qqQLNO+wxVVmJp+igPx5owe+4Z605nNB/9xN/M=";
    };
    "legacy-mcu1" = {
      date = "2026-10-21";
      rev = "a9683a456079131a0381ed75fb7a4f5514527b3c";
      hash = "sha256-yK71pZuw8H2JpidoexrrmkJ/puoxkN36gHtpMf+QZxU=";
    };
  };
  source = sources.${variant} or (throw "Unsupported AIC8800D80 variant: ${variant}");
in

stdenv.mkDerivation rec {
  pname = "aic8800d80";
  version = "unstable-${source.date}-${variant}";

  src = fetchFromGitHub {
    owner = "shenmintao";
    repo = "aic8800d80";
    inherit (source) rev hash;
  };

  nativeBuildInputs = kernel.moduleBuildDependencies;
  __structuredAttrs = true;

  makeFlags = kernelModuleMakeFlags ++ [
    "INSTALL_MOD_DIR=updates/aic8800"
    "DEPMOD=true"
  ];

  # Kbuild strips modules before generating their certificates at install time.
  dontStrip = true;

  postPatch = ''
    substituteInPlace aic.rules \
      --replace-fail /usr/bin/eject ${utilLinux}/bin/eject
  '';

  buildPhase = ''
    runHook preBuild
    local -a flagsArray
    concatTo flagsArray makeFlags makeFlagsArray
    make -C ${kernel.dev}/lib/modules/${kernel.modDirVersion}/build \
      M="$PWD/drivers/aic8800" "''${flagsArray[@]}" modules
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    local -a flagsArray
    concatTo flagsArray makeFlags makeFlagsArray
    make -C ${kernel.dev}/lib/modules/${kernel.modDirVersion}/build \
      M="$PWD/drivers/aic8800" "''${flagsArray[@]}" INSTALL_MOD_PATH="$out" INSTALL_MOD_STRIP=1 modules_install

    mkdir -p $out/lib/firmware
    cp -r fw/* $out/lib/firmware/

    install -d $out/libexec
    printf '%s\n' \
      '#!${stdenv.shell}' \
      'exec ${usbModeswitch}/bin/usb_modeswitch -c /etc/usb_modeswitch.d/1111:1111' \
      > $out/libexec/aic8800-mode-switch
    chmod 755 $out/libexec/aic8800-mode-switch
    sed -i '/ATTR{idVendor}=="1111"/c\
    ACTION=="add", SUBSYSTEM=="usb", ATTR{idVendor}=="1111", ATTR{idProduct}=="1111", RUN+="'"$out"'/libexec/aic8800-mode-switch"' aic.rules
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
