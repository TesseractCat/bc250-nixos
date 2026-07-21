{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.services.bc250-memcfg;

  packageExe = lib.getExe cfg.package;

  settingsCommands = ''
    set -euo pipefail

    currentConfig="$(${packageExe})"
  '' + lib.concatStringsSep "\n" (lib.mapAttrsToList (name: value:
    let
      requested = toString value;
      escapedName = lib.escapeShellArg name;
      escapedRequested = lib.escapeShellArg requested;
    in
      if name == "UMA_SIZE" then ''
        currentUmaSizeRaw="$(
          printf '%s\n' "$currentConfig" |
            while IFS='=' read -r key value; do
              if [ "$key" = "UMA_SIZE" ]; then
                echo "$value"
                break
              fi
            done
        )"
        if [ -n "$currentUmaSizeRaw" ]; then
          currentUmaSize="$((10#$currentUmaSizeRaw))"
        else
          currentUmaSize=""
        fi
        if [ "$currentUmaSize" = ${escapedRequested} ]; then
          echo "UMA_SIZE is already ${requested}; not writing CMOS."
        else
          ${packageExe} ${escapedName} ${escapedRequested}
        fi
      '' else ''
        ${packageExe} ${escapedName} ${escapedRequested}
      ''
  ) cfg.settings);
in
{
  options.services.bc250-memcfg = {
    enable = lib.mkEnableOption "BC-250 CMOS BIOS memory configuration tool";

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.callPackage ./package.nix { };
      description = "Package providing bc250memcfg.";
    };

    settings = lib.mkOption {
      type = lib.types.attrsOf (lib.types.oneOf [ lib.types.int lib.types.str ]);
      default = { };
      example = { UMA_SIZE = 512; };
      description = ''
        CMOS memory configuration values to apply when
        services.bc250-memcfg.applyOnBoot is enabled. These values are not
        applied by default.
      '';
    };

    applyOnBoot = lib.mkEnableOption "applying BC-250 memory configuration at boot";

    applyOnActivation = lib.mkEnableOption "applying BC-250 memory configuration during NixOS activation";
  };

  config = lib.mkIf cfg.enable (lib.mkMerge [
    {
      environment.systemPackages = [ cfg.package ];
    }

    (lib.mkIf (cfg.applyOnBoot || cfg.applyOnActivation) {
      assertions = [
        {
          assertion = cfg.settings != { };
          message = "services.bc250-memcfg.settings must not be empty when applyOnBoot or applyOnActivation is enabled.";
        }
      ];
    })

    (lib.mkIf cfg.applyOnActivation {
      system.activationScripts.bc250-memcfg.text = settingsCommands;
    })

    (lib.mkIf cfg.applyOnBoot {
      systemd.services.bc250-memcfg = {
        description = "Apply BC-250 CMOS BIOS memory configuration";
        after = [ "multi-user.target" ];
        wantedBy = [ "multi-user.target" ];

        serviceConfig = {
          Type = "oneshot";
          ExecStart = pkgs.writeShellScript "bc250-memcfg-apply" settingsCommands;
        };
      };
    })
  ]);
}
