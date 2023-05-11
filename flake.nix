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
            in rec {
              inherit (prevPkgs prev.emacs) emacs-vterm emacsql-sqlite;
              # nixpkgs.emacs without any overlays
              inherit (nixpkgs.legacyPackages.${localSystem}) emacs;

              # Stable uses emacs-src, emacs-overlay and my overlays.
              emacsStable = mkStable (applyOverlay prev.emacsUnstable { });

              # emacs-overlay GUI variants
              emacs-gtk = mkUsingToolkit prev.emacs-gtk { withGTK3 = true; };
              emacsStable-gtk = mkStable emacs-gtk;
              emacsPgtk = applyOverlay prev.emacsPgtk {
                withPgtk = true;
                withX = false;
                withNS = false;
              };
              emacsStablePgtk = mkStable emacsPgtk;

              # Add other toolkits as options since GTK crashes when
              # Emacs is run in daemon mode and the X server restarts.
              emacs-athena =
                mkUsingToolkit prev.emacs-gtk { withAthena = true; };
              emacsStable-athena = mkStable emacs-athena;
              emacs-motif = mkUsingToolkit prev.emacs-gtk { withMotif = true; };
              emacsStable-motif = mkStable emacs-motif;
              emacs-lucid = mkUsingToolkit prev.emacs-gtk { };
              emacsStable-lucid = mkStable emacs-lucid;

              # Terminal-only variants
              emacs-nox = applyOverlay prev.emacs-nox { };
              emacsStable-nox = mkStable emacs-nox;

              # Mac specific variants
              emacs-macport = applyOverlay prev.emacs-gtk
                (noDefaultUi // { withMacport = true; });
              emacsStable-macport = mkStable emacs-macport;
            })
        ];
      };

      packages = rec {
        inherit (pkgs)
          emacs emacsGit emacsPgtk emacsStable emacsStablePgtk emacsUnstable
          emacsUnstablePgtk emacsLsp emacs-nox emacsStable-nox emacsGit-nox
          emacsUnstable-nox emacs-gtk emacsStable-gtk emacs-athena
          emacsStable-athena emacs-motif emacsStable-motif emacs-lucid
          emacsStable-lucid emacs-macport emacsStable-macport;
        default = emacs;
      };
    });
}
