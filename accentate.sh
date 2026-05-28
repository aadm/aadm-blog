#!/bin/sh
# http://it.wikipedia.org/wiki/Accento_distintivo_sui_monosillabi
# é=acuto, è=grave
#
# usage: accentate.sh [-i] file
#   -i  edit file in place (default: write to stdout)

INPLACE=0
if [ "$1" = "-i" ]; then
    INPLACE=1
    shift
fi

run_sed() {
    sed -E \
        -e "s/che'/ché/g" \
        -e "s/chè/ché/g" \
        -e "s/se'/sé/g" \
        -e "s/ne'/né/g" \
        -e "s/Ne'/Né/g" \
        -e "s/bè/be'/g" \
        -e "s/Bè/Be'/g" \
        -e "s/E'/È/g" \
        -e "s/e'/è/g" \
        -e "s/u'/ù/g" \
        -e "s/a'/à/g" \
        -e "s/i'/ì/g" \
        -e "s/o'/ò/g" \
        -e "s/ pò/ po'/g" \
        "$1"
}

if [ "$INPLACE" = "1" ]; then
    tmp=$(mktemp)
    run_sed "$1" > "$tmp" && mv "$tmp" "$1"
else
    run_sed "$1"
fi


# ---------------------------------------------------------
# filtro procmail
# fonte: http://freaknet.org/asbesto/roba/accentate.html
# ---------------------------------------------------------
# SED=`which sed`
# :0 fBw
# | $SED -e "s/\=E0/a'/g" -e "s/\=E8/e'/g" \
#        -e "s/\=E9/e'/g" -e "s/\=EC/i'/g" \
#        -e "s/\=F2/o'/g" -e "s/\=F9/u'/g" \
#        -e "s/\=C0/A'/g" -e "s/\=C8/E'/g" \
#        -e "s/\=C9/E'/g" -e "s/\=C1/A'/g" \
#        -e "s/\=CC/I'/g" -e "s/\=CD/I'/g" \
#        -e "s/\=E1/a'/g" -e "s/\=ED/i'/g" \
#        -e "s/à/a'/g" -e "s/è/e'/g" \
#        -e "s/é/e'/g" -e "s/ì/i'/g" \
#        -e "s/ò/o'/g" -e "s/ù/u'/g" \
#        -e "s/\ø/o/g" -e "s/«/<>/g" -e "s/È/E'/g" \
#        -e "s/É/E'/g" -e "s/·/./g"
# ---------------------------------------------------------