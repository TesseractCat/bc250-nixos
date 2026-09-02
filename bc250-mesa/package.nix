{
  mesa,
}:

mesa.overrideAttrs (prev: {
  pname = "bc250-mesa";

  patches = (prev.patches or [ ]) ++ [
    ./patches/0001-gfx1013-compute-queue-fix.patch
  ];

  meta = prev.meta // {
    description = "Mesa patched to expose the GFX1013 compute queue on the AMD BC-250";
    longDescription = ''
      Exposes the dedicated compute queue on GFX1013 and routes it through the
      async-compute threadgroup workaround. Requires the matching patched
      amdgpu module; without it the GPU hangs. Patch from
      https://github.com/MastaG/linux-cachyos-bc250.
    '';
  };
})
