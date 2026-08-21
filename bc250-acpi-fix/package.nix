{
  lib,
  stdenvNoCC,
  fetchFromGitHub,
  acpica-tools,
  cpio,
}:

stdenvNoCC.mkDerivation rec {
  pname = "bc250-acpi-fix";
  version = "1.1.0";

  src = fetchFromGitHub {
    owner = "e-tho";
    repo = "bc250-acpi-fix";
    rev = "v1.1.0";
    hash = "sha256-DAVu5lY7ihps6Y1AlZ/X9pq9c1WXy2AbBtVIRTflzc0=";
  };

  nativeBuildInputs = [
    acpica-tools
    cpio
  ];

  installPhase = ''
    runHook preInstall

    install -Dm644 acpi_override.cpio "$out/lib/firmware/acpi/acpi_override.cpio"

    runHook postInstall
  '';

  meta = {
    description = "ACPI table overrides providing CPU idle states and frequency scaling for the AMD BC-250";
    homepage = "https://github.com/e-tho/bc250-acpi-fix";
    license = lib.licenses.mit;
    sourceProvenance = with lib.sourceTypes; [ fromSource ];
    platforms = [ "x86_64-linux" ];
  };
}
