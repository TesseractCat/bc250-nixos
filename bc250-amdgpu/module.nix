{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.hardware.bc250-amdgpu;
in
{
  options.hardware.bc250-amdgpu = {
    enable = lib.mkEnableOption "patched amdgpu kernel module for the BC-250";

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.callPackage ./package.nix {
        kernel = config.boot.kernelPackages.kernel;
      };
      defaultText = lib.literalExpression ''
        pkgs.callPackage ./package.nix {
          kernel = config.boot.kernelPackages.kernel;
        }
      '';
      description = "Package providing the patched amdgpu module.";
    };

    cuUnlock.enable = lib.mkEnableOption "40 CU unlock (amdgpu.bc250_cc_write_mode=3)";
  };

  config = lib.mkIf cfg.enable (lib.mkMerge [
    {
      boot.extraModulePackages = [ cfg.package ];
    }

    (lib.mkIf cfg.cuUnlock.enable {
      boot.extraModprobeConfig = ''
        options amdgpu bc250_cc_write_mode=3
      '';

      assertions = [
        {
          assertion = !config.services.bc250-cu-live-manager.enable;
          message = ''
            hardware.bc250-amdgpu.cuUnlock and services.bc250-cu-live-manager
            both write SPI_PG_ENABLE_STATIC_WGP_MASK. Enable only one.
          '';
        }
      ];
    })
  ]);
}
