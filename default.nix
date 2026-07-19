{ config, lib, ... }:

let
  cfg = config.hardware.bc250;
in
{
  imports = [
    ./aic8800d80/module.nix
    ./bc250-cu-live-manager/module.nix
    ./cyan-skillfish-governor-smu/module.nix
    ./bc250-smu-oc/module.nix
  ];

  options.hardware.bc250 = {
    enable = lib.mkEnableOption "BC-250 board support";

    features = {
      aic8800d80.enable = lib.mkEnableOption "AIC8800D80 Wi-Fi/Bluetooth support";
      sensors.enable = lib.mkEnableOption "nct6683 sensor support" // { default = true; };
      cuLiveManager.enable = lib.mkEnableOption "BC-250 CU live manager";
      gpuGovernor.enable = lib.mkEnableOption "Cyan Skillfish GPU governor" // { default = true; };
      cpuOverclock.enable = lib.mkEnableOption "Enable CPU Overclocking service";
      cpuOverclock.configFile = lib.mkOption {
        type = lib.types.path;
        default = "/etc/overclock.conf";
        description = "Path to the generated overclock configuration file.";
      };
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

    (lib.mkIf cfg.features.gpuGovernor.enable {
      services.cyan-skillfish-governor-smu.enable = lib.mkDefault true;
    })

    (lib.mkIf cfg.features.cpuOverclock.enable {
      services.bc250-cpu-oc.enable = lib.mkDefault true;
      services.bc250-cpu-oc.configFile = cfg.features.cpuOverclock.configFile;
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
