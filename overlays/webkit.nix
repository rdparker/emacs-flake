{ isDarwin }:
self: super:
let
  inherit (super) lib;
  inherit (lib.lists) any forEach;
in {
  emacs = (super.emacs.override { }).overrideAttrs (oa:
    let
      supportedGui = any (x: builtins.elem x oa.configureFlags) [
        "--with-ns"
        "--with-mac"
        "--with-x-toolkit=gtk3"
      ];
      webKit = if isDarwin then
        super.darwin.apple_sdk.frameworks.WebKit
      else
        super.webkitgtk;

    in if supportedGui then {
      buildInputs = oa.buildInputs ++ [ webKit ];
      configureFlags = oa.configureFlags ++ [ "--with-xwidgets" ];
    } else
      { });
}
