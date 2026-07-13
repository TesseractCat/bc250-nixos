{
  lib,
  rustPlatform,
  fetchFromGitHub,
  pkg-config,
  makeWrapper,
  libdrm,
  util-linux,
  dbus,
}:

rustPlatform.buildRustPackage rec {
  pname = "cyan-skillfish-governor-smu";
  version = "unstable";

  src = fetchFromGitHub {
    owner = "filippor";
    repo = "cyan-skillfish-governor";
    rev = "smu";
    hash = "sha256-3XvOVvX0/uvzxnnxS2iP8uaH20V28VIxeQaBljeP4DU=";
  };

  cargoHash = "sha256-zlAVGLGnub2Gc0Bkzb5GU9NBAJ2YWLhIG8JOa+1wHx8=";

  nativeBuildInputs = [
    pkg-config
    makeWrapper
  ];

  buildInputs = [
    libdrm
    dbus
  ];

  postInstall = ''
    wrapProgram "$out/bin/cyan-skillfish-governor-smu" \
     --prefix PATH : ${lib.makeBinPath [
       util-linux
       dbus
    ]}

    install -Dm644 default-config.toml \
      "$out/share/${pname}/config.toml"

    if [ -f com.cyanskillfish.Governor.conf ]; then
      install -Dm644 com.cyanskillfish.Governor.conf \
        "$out/share/dbus-1/system.d/com.cyanskillfish.Governor.conf"
    fi

    if [ -f scripts/cyan-skillfish-performance-mode ]; then
      install -Dm755 scripts/cyan-skillfish-performance-mode \
        "$out/bin/cyan-skillfish-performance-mode"

      wrapProgram "$out/bin/cyan-skillfish-performance-mode" \
        --prefix PATH : ${lib.makeBinPath [ dbus ]}
    fi
  '';

  meta = {
    description = "GPU governor for the AMD Cyan Skillfish APU";
    homepage = "https://github.com/filippor/cyan-skillfish-governor/tree/smu";
    license = lib.licenses.mit;
    platforms = lib.platforms.linux;
    mainProgram = "cyan-skillfish-governor-smu";
  };
}
