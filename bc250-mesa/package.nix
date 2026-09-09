{
  mesa,
}:

mesa.overrideAttrs (prev: {
  pname = "bc250-mesa";

  patches = (prev.patches or [ ]) ++ [
    ./patches/0001-gfx1013-compute-queue-fix.patch
    ./patches/0002-gfx1013-mesh-task-shaders.patch
    ./patches/0003-gfx1013-taskmesh-queries.patch
    ./patches/0004-radv-gfx103.patch
    ./patches/0005-bc250-fsr4-v3.patch
    ./patches/0006-bc250-fsr4-combined-unroll.patch
    ./patches/0007-bc250-fsr4-imageprep-texture.patch
    ./patches/0008-bc250-fsr4-resolution-variants.patch
  ];

  meta = prev.meta // {
    description = "Mesa patched with GFX1013 fixes for the AMD BC-250";
    longDescription = ''
      Exposes the dedicated compute queue on GFX1013 and routes it through the
      async-compute threadgroup workaround. Requires the matching patched
      amdgpu module; without it the GPU hangs. Patches from
      https://github.com/MastaG/linux-cachyos-bc250.
    '';
  };
})
