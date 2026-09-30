_: prev: {
  perl = prev.perl.overrideAttrs (old: {
    postPatch = (old.postPatch or "") + ''
      substituteInPlace src/bsearch.c \
        --replace-fail 'void *bsearch(' 'void *tsp_bsearch('
      substituteInPlace src/tsp_unicode.h \
        --replace-fail 'return bsearch(' 'return tsp_bsearch('
    '';
  });
}
