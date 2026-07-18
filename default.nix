{ config, lib, ... }:

let
  cfg = config.hardware.bc250;
in
{
  imports = [
    ./aic8800d80/module.nix
    ./bc250-cu-live-manager/module.nix
    ./cyan-skillfish-governor-smu/module.nix
  ];

  options.hardware.bc250 = {
    enable = lib.mkEnableOption "BC-250 board support";

    features = {
      aic8800d80.enable = lib.mkEnableOption "AIC8800D80 Wi-Fi/Bluetooth support";
      sensors.enable = lib.mkEnableOption "nct6683 sensor support" // { default = true; };
      cuLiveManager.enable = lib.mkEnableOption "BC-250 CU live manager";
      governor.enable = lib.mkEnableOption "Cyan Skillfish SMU governor" // { default = true; };
      zswap.enable = lib.mkEnableOption "recommended zswap settings" // { default = true; };
    };
  };

  config = lib.mkIf cfg.enable (lib.mkMerge [
    (lib.mkIf cfg.features.aic8800d80.enable {
      hardware.aic8800d80.enable = lib.mkDefault true;
    })

    (lib.mkIf cfg.features.sensors.enable {
      boot.kernelModules = [ "nct6683" ];
      boot.extraModprobeConfig = ''
        options nct6683 force=true
      '';
    })

    (lib.mkIf cfg.features.cuLiveManager.enable {
      services.bc250-cu-live-manager.enable = lib.mkDefault true;
    })

    (lib.mkIf cfg.features.governor.enable {
      services.cyan-skillfish-governor-smu.enable = lib.mkDefault true;
    })

    (lib.mkIf cfg.features.zswap.enable {
      boot.kernel.sysctl = {
        "vm.swappiness" = lib.mkDefault 180;
      };
      boot.zswap = {
        enable = lib.mkDefault true;
        compressor = lib.mkDefault "lz4";
      };
    })
  ]);
}
