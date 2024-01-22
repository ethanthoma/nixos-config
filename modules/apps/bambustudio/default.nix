{ pkgs, lib, ... }:

pkgs.stdenv.mkDerivation rec {
    pname = "BambuStudio";
    version = "01.08.00.62";

    src = pkgs.fetchFromGitHub {
        owner = "bambulab";
        repo = "BambuStudio";
        rev = "v${version}";
        sha256 = "Rb8YNf+ZQ8+9jAP/ZLze0PfY/liE7Rr2bJX33AENsbg=";
    };

    nativeBuildInputs = with pkgs; [
        cmake 
        pkgconf
        boost
    ];

    buildInputs = with pkgs; [
        clang 
        tbb
        openssl
        curl
        glew
        glfw
        cereal
        nlopt
        openvdb
        eigen
        openexr
        cgal
        opencascade-occt
        wxGTK31
        dbus
        pngpp

        gcc
        git
        mesa
        m4
        wayland
        libxkbcommon
        wayland-protocols
        extra-cmake-modules
        mesa_glu
        cairo
        gtk3
        libsoup
        webkitgtk
        gst_all_1.gstreamer
        gst_all_1.gst-plugins-base
        gst_all_1.gst-plugins-good
        gst_all_1.gst-plugins-bad
        mesa-demos
    ];

    cmakeFlags = with pkgs; [ 
        "-DwxWidgets_LIBRARIES=${wxGTK31}/lib"
    ];

    buildPhase = ''
        # Building dependencies
        echo $wxGTK31
        echo $wxGTK31.out
        cd $src/deps
        mkdir build && cd build
        cmake ../ -DDESTDIR="$out/BambuStudio_dep" -DCMAKE_BUILD_TYPE=Release -DDEP_WX_GTK3=1
        make -j$NIX_BUILD_CORES

        # Building Bambu Studio
        cd $src
        mkdir build && cd build
        cmake .. -DSLIC3R_STATIC=ON -DSLIC3R_GTK=3 -DBBL_RELEASE_TO_PUBLIC=1 -DCMAKE_PREFIX_PATH="$out/BambuStudio_dep/usr/local" -DCMAKE_BUILD_TYPE=Release
        cmake --build . --target install --config Release -j$NIX_BUILD_CORES
    '';

    installPhase = ''
        mkdir -p $out/bin
        cp -r $src/install_dir/* $out/bin/
    '';

    meta = with lib; {
        description = "Bambu Studio - 3D Printing Software";
        homepage = "https://github.com/bambulab/BambuStudio";
        license = licenses.gpl3; # Assuming GPL3, replace if different
        maintainers = with maintainers; [ /* maintainers */ ];
    };
}

