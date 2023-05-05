{ isDarwin }:
self: super:
let
  inherit (super) lib;
  inherit (lib.lists) any forEach;
in {
  emacs = (super.emacs.override { }).overrideAttrs (oa:
    let
      gui = any (x: builtins.elem x oa.configureFlags)
        ([ "--with-ns" "--with-mac" "--with-pgtk" ]
          ++ (forEach [ "gtk2" "gtk3" "motif" "athena" "lucid" ]
            (x: "--with-x-toolkit=${x}")));
    in {
      buildInputs = oa.buildInputs ++ (if gui then
        [
          (if isDarwin then
            super.darwin.apple_sdk.frameworks.WebKit
          else
            super.webkitgtk)
        ]
      else
        [ ]);
      configureFlags = oa.configureFlags ++ lib.optional gui "--with-xwidgets";
    });
}
