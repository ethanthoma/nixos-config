{ pkgs, lib, ... }:

pkgs.stdenv.mkDerivation rec {
  pname = "thorium-browser";
  version = "128.0.6613.189";

  src = pkgs.fetchurl {
    url = "https://github.com/Alex313031/thorium/releases/download/M${version}/thorium-browser_${version}_AVX2.deb";
    hash = "sha256-oid72E4n9jAQsCUrztlyj56Gd0+pz735y6b5COMA4tg=";
  };

  nativeBuildInputs = with pkgs; [
    autoPatchelfHook
    dpkg
    wrapGAppsHook
    qt6.wrapQtAppsHook
  ];

  buildInputs = with pkgs; [
    stdenv.cc.cc.lib
    alsa-lib
    at-spi2-atk
    at-spi2-core
    cairo
    cups
    curl
    dbus
    expat
    ffmpeg
    fontconfig
    freetype
    glib
    glibc
    gtk3
    gtk4
    libcanberra
    liberation_ttf
    libexif
    libglvnd
    libkrb5
    libnotify
    libpulseaudio
    libu2f-host
    libva
    libxkbcommon
    mesa
    nspr
    nss
    qt6.qtbase
    pango
    pciutils
    pipewire
    speechd
    udev
    unrar
    vaapiVdpau
    vulkan-loader
    wayland
    wget
    xdg-utils
    xfce.exo
    xorg.libxcb
    xorg.libX11
    xorg.libXcursor
    xorg.libXcomposite
    xorg.libXdamage
    xorg.libXext
    xorg.libXfixes
    xorg.libXi
    xorg.libXrandr
    xorg.libXrender
    xorg.libXtst
    xorg.libXxf86vm
  ];

  autoPatchelfIgnoreMissingDeps = [
    "libQt5Widgets.so.5"
    "libQt5Gui.so.5"
    "libQt5Core.so.5"
  ];

  installPhase = ''
    runHook preInstall
    mkdir -p $out
    cp -r usr/* $out
    cp -r etc $out
    cp -r opt $out
    ln -sf $out/opt/chromium.org/thorium/thorium-browser $out/bin/thorium-browser
    substituteInPlace $out/share/applications/thorium-shell.desktop \
    --replace /usr/bin $out/bin \
    --replace /opt $out/opt
    substituteInPlace $out/share/applications/thorium-browser.desktop \
    --replace /usr/bin $out/bin \
    --replace StartupWMClass=thorium StartupWMClass=thorium-browser \
    --replace Icon=thorium-browser Icon=$out/opt/chromium.org/thorium/product_logo_256.png
    addAutoPatchelfSearchPath $out/chromium.org/thorium
    addAutoPatchelfSearchPath $out/chromium.org/thorium/lib
    substituteInPlace $out/opt/chromium.org/thorium/thorium-browser \
    --replace 'export LD_LIBRARY_PATH' "export LD_LIBRARY_PATH=\$LD_LIBRARY_PATH:${lib.makeLibraryPath buildInputs}:$out/chromium.org/thorium:$out/chromium.org/thorium/lib" \
    --replace /usr $out
    runHook postInstall
  '';
}
