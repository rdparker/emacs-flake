{
  description =
    "Emacs with Pure-GTK, vterm, yabai and system-appearance support";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-22.11";
    flake-utils.url = "github:numtide/flake-utils";
    emacs-overlay.url = "github:nix-community/emacs-overlay";
    emacs-overlay.inputs.nixpkgs.follows = "nixpkgs";
    emacs-overlay.inputs.flake-utils.follows = "flake-utils";

    # Non-flakes
    emacs-patches-src.flake = false;
    emacs-patches-src.url = "github:d12frosted/homebrew-emacs-plus";

    emacs-src.flake = false;
    emacs-src.url = "github:emacs-mirror/emacs/emacs-29";

    emacs-vterm-src.flake = false;
    emacs-vterm-src.url = "github:akermu/emacs-libvterm";

    # Only used by shell.nix
    flake-compat.flake = false;
    flake-compat.url = "github:edolstra/flake-compat";
  };

  outputs = { self, nixpkgs, emacs-overlay, emacs-patches-src, emacs-src
    , emacs-vterm-src, flake-utils, ... }:
    let
      inherit (flake-utils.lib) eachDefaultSystem eachSystem;
      inherit (nixpkgs.lib) mkIf platforms;
      isDarwin = system: (builtins.elem system platforms.darwin);
    in eachDefaultSystem (localSystem: rec {
      pkgs = import nixpkgs {
        inherit localSystem;
        overlays = [
          emacs-overlay.overlays.emacs
          (final: prev: {
            emacs-vterm = prev.stdenv.mkDerivation rec {
              pname = "emacs-vterm";
              version = "master";

              src = emacs-vterm-src;

              nativeBuildInputs = [ prev.cmake prev.libtool prev.glib.dev ];

              buildInputs = [ prev.glib.out prev.libvterm-neovim prev.ncurses ];

              cmakeFlags = [ "-DUSE_SYSTEM_LIBVTERM=yes" ];

              preConfigure = ''
                echo "include_directories(\"${prev.glib.out}/lib/glib-2.0/include\")" >> CMakeLists.txt
                echo "include_directories(\"${prev.glib.dev}/include/glib-2.0\")" >> CMakeLists.txt
                echo "include_directories(\"${prev.ncurses.dev}/include\")" >> CMakeLists.txt
                echo "include_directories(\"${prev.libvterm-neovim}/include\")" >> CMakeLists.txt
              '';

              installPhase = ''
                mkdir -p $out
                cp ../vterm-module.so $out
                cp ../vterm.el $out
              '';
            };

            emacs = (prev.emacsPgtk.override {
              withGTK3 = true;
              withXwidgets = true;
            }).overrideAttrs (o: rec {
              src = emacs-src;

              buildInputs = o.buildInputs ++ [
                (if (isDarwin localSystem) then
                  prev.darwin.apple_sdk.frameworks.WebKit
                else
                  prev.webkitgtk)
              ];

              patches = o.patches ++ [
                "${emacs-patches-src}/patches/emacs-29/fix-window-role.patch"
                "${emacs-patches-src}/patches/emacs-29/system-appearance.patch"
              ];

              postInstall = o.postInstall + ''
                cp ${final.emacs-vterm}/vterm.el $out/share/emacs/site-lisp/vterm.el
                cp ${final.emacs-vterm}/vterm-module.so $out/share/emacs/site-lisp/vterm-module.so
              '';

              CFLAGS = "-DMAC_OS_X_VERSION_MAX_ALLOWED=110203 -g -O2";
            });
          })
        ];
      };

      packages = rec {
        emacs = pkgs.emacs;
        default = emacs;
      };
    });
}
