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
    in eachDefaultSystem (localSystem:
      let
        ifDarwinElse = darwin: other:
          if (isDarwin localSystem) then darwin else other;
      in rec {
        pkgs = import nixpkgs {
          inherit localSystem;
          overlays = [
            emacs-overlay.overlays.emacs
            (final: prev:
              let
                overrideEmacs = { pkg, src ? pkg.src, nox ? false }:
                  (pkg.override (if nox then
                    { }
                  else {
                    withGTK3 = true;
                    withXwidgets = true;
                  })).overrideAttrs (o: rec {
                    inherit src;

                    buildInputs = if nox then
                      o.buildInputs
                    else
                      (o.buildInputs ++ [
                        (ifDarwinElse prev.darwin.apple_sdk.frameworks.WebKit
                          prev.webkitgtk)
                      ]);

                    patches = o.patches ++ [
                      "${emacs-patches-src}/patches/emacs-29/fix-window-role.patch"
                    ];

                    postInstall = o.postInstall + ''
                      cp ${final.emacs-vterm}/vterm.el $out/share/emacs/site-lisp/vterm.el
                      cp ${final.emacs-vterm}/vterm-module.so $out/share/emacs/site-lisp/vterm-module.so
                    '';

                    CFLAGS = ifDarwinElse
                      "-DMAC_OS_X_VERSION_MAX_ALLOWED=110203 -g -O2" "-g -O2";
                  });
              in rec {
                emacs-vterm = prev.stdenv.mkDerivation rec {
                  pname = "emacs-vterm";
                  version = "master";

                  src = emacs-vterm-src;

                  nativeBuildInputs = [ prev.cmake prev.libtool prev.glib.dev ];

                  buildInputs =
                    [ prev.glib.out prev.libvterm-neovim prev.ncurses ];

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

                emacsGit = overrideEmacs { pkg = prev.emacsGit; };
                emacsPgtk = overrideEmacs { pkg = prev.emacsPgtk; };
                emacsUnstable = overrideEmacs { pkg = prev.emacsUnstable; };
                emacsUnstablePgtk =
                  overrideEmacs { pkg = prev.emacsUnstablePgtk; };
                emacsLsp = overrideEmacs { pkg = prev.emacsLsp; };
                emacsGit-nox = overrideEmacs {
                  pkg = prev.emacsGit-nox;
                  nox = true;
                };
                emacsUnstable-nox = overrideEmacs {
                  pkg = prev.emacsUnstable-nox;
                  nox = true;
                };

                # The Stable packages are taken from the emacs-src input.
                emacsStable = overrideEmacs {
                  pkg = prev.emacsGit;
                  src = emacs-src;
                };
                emacsStablePgtk = overrideEmacs {
                  pkg = prev.emacsPgtk;
                  src = emacs-src;
                };
                emacsStable-nox = overrideEmacs {
                  pkg = prev.emacs-nox;
                  src = emacs-src;
                  nox = true;
                };

                emacs = ifDarwinElse emacsStablePgtk emacsStable;
              })
          ];
        };

        packages = rec {
          inherit (pkgs)
            emacs emacsGit emacsPgtk emacsStable emacsStablePgtk emacsUnstable
            emacsUnstablePgtk emacsLsp emacsStable-nox emacsGit-nox
            emacsUnstable-nox;
          default = emacs;
        };
      });
}
