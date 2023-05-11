# Adds emacsql-sqlite to nixpkgs and adds its supporting Emacs Lisp file
# and library module to Emacs so that it is automatically available.
{ emacsql-sqlite-src }:
self: super: rec {
  emacsql-sqlite = super.stdenv.mkDerivation rec {
    pname = "emacsql-sqlite";
    version = "3.1.1";

    meta = with super.lib; {
      description = "Custom SQLite for EmacSQL";
      license = licenses.free;
      mainProgram = "emacsql-sqlite";
    };

    src = emacsql-sqlite-src;

    sourceRoot = "source/sqlite";

    installPhase = ''
      runHook preInstall

      install -Dm555 -t $out/bin ${meta.mainProgram}

      runHook postInstall
    '';
  };

  emacs = (super.emacs.override { }).overrideAttrs (oa: {
    postPatch = oa.postPatch + ''
      echo '(setq emacsql-sqlite-executable "${self.emacsql-sqlite}/emacsql-sqlite")' >> "lisp/site-init.el"
    '';
  });
}
