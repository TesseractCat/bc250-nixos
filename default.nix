{ config, lib, ... }:

let
  cfg = config.hardware.bc250;
in
{
  imports = [
    ./aic8800d80/module.nix
    ./bc250-cu-live-manager/module.nix
    ./bc250-memcfg/module.nix
    ./cyan-skillfish-governor-smu/module.nix
    ./bc250-smu-oc/module.nix
  ];

  options.hardware.bc250 = {
    enable = lib.mkEnableOption "BC-250 board support";

    features = {
      aic8800d80.enable = lib.mkEnableOption "AIC8800D80 Wi-Fi/Bluetooth support";
      sensors.enable = lib.mkEnableOption "nct6687 sensor support" // { default = true; };
      cuLiveManager.enable = lib.mkEnableOption "BC-250 CU live manager";
      vramSplit = lib.mkOption {
        type = lib.types.nullOr lib.types.int;
        default = null;
        example = 512;
        description = "Static VRAM/UMA split in MB to write with bc250memcfg. This value represents the minimum amount of memory that will be allocated to VRAM, however additional memory can be dynamically allocated. Null leaves CMOS unchanged.";
      };
      vramDynamicSplit = lib.mkOption {
        type = lib.types.nullOr lib.types.int;
        default = null;
        example = 4096;
        description = "How much additional memory can be dynamically allocated to VRAM, in MB (converted to 4 KiB pages and passed as ttm.pages_limit). Null leaves it unset. If unset, the linux kernel typically sets this value to 1/2 of the RAM allocation.";
      };
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
    {
      services.bc250-memcfg.enable = true;

      assertions = [
        {
          assertion = cfg.features.vramSplit == null || cfg.features.vramSplit > 0;
          message = "hardware.bc250.features.vramSplit must be null or a positive MB value.";
        }
        {
          assertion = cfg.features.vramDynamicSplit == null || cfg.features.vramDynamicSplit > 0;
          message = "hardware.bc250.features.vramDynamicSplit must be null or a positive MB value.";
        }
      ];
    }

    (lib.mkIf cfg.features.aic8800d80.enable {
      hardware.aic8800d80.enable = lib.mkDefault true;
    })

    (lib.mkIf cfg.features.sensors.enable {
      boot.extraModulePackages = [ config.boot.kernelPackages.nct6687d ];
      boot.kernelModules = [ "nct6687" ];
      boot.extraModprobeConfig = ''
        options nct6687 force=true
      '';
    })

    (lib.mkIf cfg.features.cuLiveManager.enable {
      services.bc250-cu-live-manager.enable = lib.mkDefault true;
    })

    (lib.mkIf (cfg.features.vramSplit != null) {
      services.bc250-memcfg.applyOnActivation = true;
      services.bc250-memcfg.applyOnBoot = true;
      services.bc250-memcfg.settings.UMA_SIZE = lib.mkDefault cfg.features.vramSplit;
    })

    (lib.mkIf (cfg.features.vramDynamicSplit != null) {
      boot.kernelParams = [
        "ttm.pages_limit=${toString (cfg.features.vramDynamicSplit * 256)}"
      ];
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
