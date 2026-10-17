{
  lib,
  rustPlatform,
  fetchFromGitHub,
  cargo-tauri,
  fetchPnpmDeps,
  pnpmConfigHook,
  pnpm,
  nodejs,
  pkg-config,
  protobuf,
  perl,
  makeWrapper,
  wrapGAppsHook4,
  steam-run,
  mangohud,
  openssl,
  webkitgtk_4_1,
  libsoup_3,
  glib-networking,
  librsvg,
  libayatana-appindicator,
  cacert,
}:

rustPlatform.buildRustPackage (finalAttrs: {
  pname = "twintaillauncher";
  version = "2.5.2";

  src = fetchFromGitHub {
    owner = "TwintailTeam";
    repo = "TwintailLauncher";
    tag = "ttl-v${finalAttrs.version}";
    hash = "sha256-b8z6i0PTL9IagFDH0B+Y0Hpw1PUI5iwMeOcccfg8yLU=";
  };

  cargoRoot = "src-tauri";
  buildAndTestSubdir = finalAttrs.cargoRoot;
  cargoHash = "sha256-EvA3VzB+J8gD+nzf4KCTD2hIvsMOc8JmsVTjsBKazkM=";

  pnpmDeps = fetchPnpmDeps {
    inherit (finalAttrs) pname version src;
    fetcherVersion = 4;
    hash = "sha256-yJFTycwYSiOJ51WJn/IzrxLDJU1p71w6UAV5atTaqeY=";
  };

  nativeBuildInputs = [
    cargo-tauri.hook
    pnpmConfigHook
    pnpm
    nodejs
    pkg-config
    protobuf
    perl
    makeWrapper
    wrapGAppsHook4
  ];

  buildInputs = [
    openssl
    webkitgtk_4_1
    libsoup_3
    glib-networking
    librsvg
    libayatana-appindicator
  ];

  preFixup = ''
    gappsWrapperArgs+=(
      --prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath [ libayatana-appindicator ]}
      --set WEBKIT_DISABLE_DMABUF_RENDERER 1
      --set GDK_BACKEND x11
      --set WEBKIT_DISABLE_COMPOSITING_MODE 1
      --set SSL_CERT_FILE "${cacert}/etc/ssl/certs/ca-bundle.crt"
      --set NIX_SSL_CERT_FILE "${cacert}/etc/ssl/certs/ca-bundle.crt"
      --set GTK_IM_MODULE simple
    )
  '';

  postFixup = ''
    mv $out/bin/twintaillauncher $out/bin/.twintaillauncher-real
    
    cat > $out/bin/twintaillauncher <<EOF
    #!/bin/sh
    export PATH="${lib.makeBinPath [ mangohud ]}:\$PATH"
    exec ${steam-run}/bin/steam-run $out/bin/.twintaillauncher-real "\$@"
    EOF
    
    chmod +x $out/bin/twintaillauncher
  '';

  meta = {
    description = "Multi-platform launcher for anime games";
    homepage = "https://github.com/TwintailTeam/TwintailLauncher";
    license = lib.licenses.gpl3Only;
    platforms = [ "x86_64-linux" ];
    mainProgram = "twintaillauncher";
  };
})
