#!/bin/bash
set -xv
EXTENSIONS=`cat extensions.txt`
TMPDIR=`mktemp -d`
GITDIR="${TMPDIR}/GIT_L10N"
GITSOURCE="https://github.com/civicrm/civicrm-l10n-extensions.git"
git clone "${GITSOURCE}" "${GITDIR}"
for EXT in ${EXTENSIONS}
do
  PO="${GITDIR}/po/${EXT}/fr_FR/${EXT}.po"
  RPO="po/${EXT}/fr_FR/${EXT}.po"
  QUEUE="${EXT}/queue"
  LAST_COMMIT=""
  OVERRIDE="${EXT}/override.po"
  if [ -f "$PO" ]
  then
    install -d "${EXT}"
    if [ ! -f "${OVERRIDE}" ]
    then
      touch "${OVERRIDE}"
    fi
    echo "${OVERRIDE}" >"${QUEUE}"
    if [ -f "${EXT}/last_commit" ]
    then
      LAST_COMMIT=`cat "${EXT}/last_commit"|head -1`
    fi
    if [ -n "${LAST_COMMIT}" ]
    then
      git -C ${GITDIR} log --oneline ${LAST_COMMIT}..HEAD ${RPO}|cut -d ' ' -f 1 >"${EXT}/diff_commits"
    else
      git -C ${GITDIR} log --oneline ${RPO}|cut -d ' ' -f 1 >"${EXT}/diff_commits"
    fi
    NEW_LAST_COMMIT=`head -1 "${EXT}/diff_commits"`
    for COMMIT in `cat "${EXT}/diff_commits"`
    do
      git -C ${GITDIR} show ${COMMIT}:${RPO} >${PO}.${COMMIT}
      xgettext -L PO --no-location -o ${PO}.conv.${COMMIT} ${PO}.${COMMIT}
      if [ -f "${PO}.conv.${COMMIT}" ]
      then
        echo "${PO}.conv.${COMMIT}" >>"${QUEUE}"
      fi
    done
    if [ -f "${EXT}/${EXT}.po" ]
    then
       echo "${EXT}/${EXT}.po" >>"${QUEUE}"
    fi
    msgcat --use-first -f ${QUEUE} -o ${EXT}/result.po
    if [ -f "${EXT}/result.po" ]
    then
      mv "${EXT}/result.po" "${EXT}/${EXT}.po"
      if [ -n "${NEW_LAST_COMMIT}" ]
      then
        echo "${NEW_LAST_COMMIT}">"${EXT}/last_commit"
      else
        echo "NEW_LAST_COMMIT is empty for ${EXT}"
      fi
    fi
    rm -f "${EXT}/diff_commits"
    rm -f "${QUEUE}"
  else
    echo "WARNING : ${EXT} is not translated ; skipping the extension"
  fi
done

rm -Rf ${TMPDIR}
