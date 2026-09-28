{
  lib,
  kernel,
  flex,
  bison,
  python3,
  bc,
  zlib,
}:

kernel.stdenv.mkDerivation {
  pname = "bc250-amdgpu";
  version = kernel.version;

  inherit (kernel) src postPatch;

  nativeBuildInputs = kernel.moduleBuildDependencies ++ [
    flex
    bison
    python3
    bc
  ];

  # Required by resolve_btfids during modules_prepare. Without it,
  # CONFIG_DEBUG_INFO_BTF must be disabled, and the resulting configuration
  # mismatch prevents the module from loading.
  buildInputs = [ zlib ];

  # Numbered as in https://github.com/MastaG/linux-cachyos-bc250
  patches = [
    ./patches/0001-bc250-8core-telemetry-gpu-activity.patch
    ./patches/0003-gfx1013-pasid-tlb-invalidation.patch
    ./patches/0004-gfx1013-compute-gfxoff-guard.patch
    ./patches/0005-bc250-kfd-flush-tlb-by-runlist.patch
    ./patches/0006-amdgpu-ttm-null-page-guard.patch
    ./patches/0007-cyan-skillfish-sclk-range.patch
    ./patches/0008-bc250-40cu-unlock.patch
    ./patches/0009-dcn201-hdmi21-pcon.patch
    ./patches/0010-dcn201-enable-dsc.patch
    ./patches/0011-cs-relink-after-long-blank.patch
    ./patches/0012-ch7218-pcon-quirk.patch
    ./patches/0013-ch7218-dsc-restore.patch
    ./patches/0014-pcon-force-dsc.patch
    ./patches/0015-bc250-psp-ccp.patch
  ];

  kernelDev = kernel.dev;
  kernelVersion = kernel.modDirVersion;
  modulePath = "drivers/gpu/drm/amd/amdgpu";

  buildPhase = ''
    runHook preBuild

    patchShebangs .

    builtKernel=$kernelDev/lib/modules/$kernelVersion/build
    cp "$builtKernel/Module.symvers" .
    cp "$builtKernel/.config" .
    cp "$kernelDev/vmlinux" .

    make "-j$NIX_BUILD_CORES" modules_prepare
    make "-j$NIX_BUILD_CORES" M=$modulePath modules

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    make \
      INSTALL_MOD_PATH="$out" \
      XZ="xz -T$NIX_BUILD_CORES" \
      M="$modulePath" \
      modules_install

    runHook postInstall
  '';

  meta = {
    description = "amdgpu kernel module patched for the AMD BC-250";
    longDescription = ''
      Rebuilds the in-tree amdgpu module with GFX1013 patches from
      https://github.com/MastaG/linux-cachyos-bc250.
    '';
    license = lib.licenses.gpl2Only;
    platforms = [ "x86_64-linux" ];
  };
}
