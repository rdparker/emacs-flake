{
  description =
    "Emacs with Pure-GTK, vterm, yabai and system-appearance support";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-23.05";
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

    # Pinned to version 3.1.1
    emacsql-sqlite-src.flake = false;
    emacsql-sqlite-src.url =
      "github:magit/emacsql?rev=c1a44076c0e44d5730b67b13c0e741f66f52fc85";

    # Only used by shell.nix
    flake-compat.flake = false;
    flake-compat.url = "github:edolstra/flake-compat";
  };

  outputs = { self, nixpkgs, emacs-overlay, emacs-patches-src, emacs-src
    , emacs-vterm-src, emacsql-sqlite-src, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem (localSystem: rec {
      pkgs = import nixpkgs {
        inherit localSystem;
        overlays = [
          emacs-overlay.overlays.emacs
          (final: prev:
            let
              myOverlay = import ./overlays {
                inherit emacs-patches-src emacs-vterm-src emacsql-sqlite-src;
              };
              prevPkgs = pkg: myOverlay final (prev // { emacs = pkg; });
              applyOverlay = pkg: args: (prevPkgs pkg).emacs.override args;
              noDefaultUi = {
                withNS = false; # Darwin always enables this
                withGTK3 = false; # emacs-overlay usually enables this
              };
              mkUsingToolkit = pkg: toolkit:
                applyOverlay pkg ({
                  withX = true; # Avoid -nox
                } // noDefaultUi // toolkit);
              mkStable = pkg: pkg.overrideAttrs (oa: rec { src = emacs-src; });

              # Stable uses emacs-src, emacs-overlay and my overlays.
              emacs-stable = mkStable (applyOverlay prev.emacs-unstable { });

              # emacs-overlay GUI variants
              emacs-gtk = mkUsingToolkit prev.emacs-gtk { withGTK3 = true; };
              emacs-stable-gtk = mkStable emacs-gtk;
              emacs-pgtk = applyOverlay prev.emacs-pgtk {
                withPgtk = true;
                withX = false;
                withNS = false;
              };
              emacs-stable-pgtk = mkStable emacs-pgtk;

              # Add other toolkits as options since GTK crashes when
              # Emacs is run in daemon mode and the X server restarts.
              emacs-athena =
                mkUsingToolkit prev.emacs-gtk { withAthena = true; };
              emacs-stable-athena = mkStable emacs-athena;
              emacs-motif = mkUsingToolkit prev.emacs-gtk { withMotif = true; };
              emacs-stable-motif = mkStable emacs-motif;
              emacs-lucid = mkUsingToolkit prev.emacs-gtk { };
              emacs-stable-lucid = mkStable emacs-lucid;

              # Terminal-only variants
              emacs-nox = applyOverlay prev.emacs-nox { };
              emacs-stable-nox = mkStable emacs-nox;

              # Mac specific variants
              emacs-macport = applyOverlay prev.emacs-gtk
                (noDefaultUi // { withMacport = true; });
              emacs-stable-macport = mkStable emacs-macport;
            in rec {
              inherit (prevPkgs prev.emacs) emacs-vterm emacsql-sqlite;

              # nixpkgs.emacs without any overlays
              inherit (nixpkgs.legacyPackages.${localSystem}) emacs;

              # Stable uses emacs-src, emacs-overlay and my overlays.
              inherit emacs-stable emacs-gtk emacs-stable-gtk emacs-pgtk
                emacs-stable-pgtk emacs-athena emacs-stable-athena emacs-motif
                emacs-stable-motif emacs-lucid emacs-stable-lucid emacs-nox
                emacs-stable-nox emacs-macport emacs-stable-macport;
            } // prev.lib.optionalAttrs (prev.config.allowAliases or true) {
              emacsStable = builtins.trace
                "emacsStable has been renamed to emacs-stable, please update your expression."
                emacs-stable;
              emacsStable-gtk = builtins.trace
                "emacsStable-gtk has been renamed to emacs-stable-gtk, please update your expression."
                emacs-stable-gtk;
              emacsPgtk = builtins.trace
                "emacsPgtk has been renamed to emacs-pgtk, please update your expression."
                emacs-pgtk;
              emacsStablePgtk = builtins.trace
                "emacsStablePgtk has been renamed to emacs-stable-pgtk, please update your expression."
                emacs-stable-pgtk;
              emacsStable-athena = builtins.trace
                "emacsStable-athena has been renamed to emacs-stable-athena, please update your expression."
                emacs-stable-athena;
              emacsStable-motif = builtins.trace
                "emacsStable-motif has been renamed to emacs-stable-motif, please update your expression."
                emacs-stable-motif;
              emacsStable-lucid = builtins.trace
                "emacsStable-lucid has been renamed to emacs-stable-lucid, please update your expression."
                emacs-stable-lucid;
              emacsStable-nox = builtins.trace
                "emacsStable-nox has been renamed to emacs-stable-nox, please update your expression."
                emacs-stable-nox;
              emacsStable-macport = builtins.trace
                "emacsStable-macport has been renamed to emacs-stable-macport, please update your expression."
                emacs-stable-macport;
            })
        ];
      };

      packages = rec {
        inherit (pkgs)
          emacs emacs-git emacs-pgtk emacs-stable emacs-stable-pgtk
          emacs-unstable emacs-unstable-pgtk emacsLsp emacs-nox emacs-stable-nox
          emacs-git-nox emacs-unstable-nox emacs-gtk emacs-stable-gtk
          emacs-athena emacs-stable-athena emacs-motif emacs-stable-motif
          emacs-lucid emacs-stable-lucid emacs-macport emacs-stable-macport;
        default = emacs;
      };
    });
}
