{ emacs-patches-src, emacs-vterm-src, emacsql-sqlite-src }:
self: super:
with super;
let
  inherit (lib) optional platforms;
  inherit (lib.lists) any forEach;
  inherit (stdenv) isDarwin;
  darwinPatch =
    optional isDarwin (import ./darwin.nix { inherit emacs-patches-src; });
  emacsqlOverlay =
    [ (import ./emacsql-sqlite.nix { inherit emacsql-sqlite-src; }) ];
  webKitOverlay = [ (import ./webkit.nix { inherit isDarwin; }) ];
  vtermOverlay = [ (import ./emacs-vterm.nix { inherit emacs-vterm-src; }) ];
  overlays = darwinPatch ++ emacsqlOverlay ++ webKitOverlay ++ vtermOverlay;
in super.lib.composeManyExtensions overlays self super
