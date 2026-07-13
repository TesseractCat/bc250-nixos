# bc250-nixos

Simple NixOS module for BC250. Comes with wrapper modules and recommended settings for:
 - CPU governor (Cyan Skillfish SMU)
 - ZRam
 - CU unlocking (bc250-cu-live-manager)
    - Make sure to test the stability of your CU unlock before enabling this

Also comes with a wrapper for the AIC8800d80 driver, a chipset used in some WiFi dongles.

## Usage

Not really designed with Flakes in mind, but feel free to submit a PR.

```nix
{
  imports = [
    ./path/to/bc250-nixos
  ];

  hardware.bc250 = {
    enable = true;

    features = {
      # Disabled by default
      aic8800d80.enable = false;
      cuLiveManager.enable = false;

      # Enabled by default
      sensors.enable = true;
      governor.enable = true;
      zram.enable = true;
    };
  };
}
```
