#!/bin/bash
set -xv
EXTENSIONS=`cat extensions.txt`
for EXT in ${EXTENSIONS}
do
  POFILE="${EXT}/${EXT}.po"
  MOFILE="${EXT}/${EXT}.mo"
  if [ -f "${POFILE}" ]
  then
    msgfmt -o "${MOFILE}" "${POFILE}"
  else
    echo "Source file not found for EXT ${EXT}"
  fi
done
