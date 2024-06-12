#!/usr/bin/env bash

if [ -z "$1" ] ; then
	echo "Usage: $0 <EAP-Version> [EAP-XP-Version], e.g. $0 jboss-eap-7.4.17 jboss-eap-xp-4.0.2"
	exit
else
	EAP_VERSION=$1
fi

if [ -z "$2" ] ; then
	EAP_XP_VERSION=none
	echo No EAP XP patch supplied
else
	EAP_XP_VERSION=$2
fi

BASE_ZIP=jboss-eap-7.4.0.zip
PATCH_ZIP=${EAP_VERSION}-patch.zip
XP_PATCH_ZIP=${EAP_XP_VERSION}-patch.zip
XP_MANAGER=${EAP_XP_VERSION}-manager.jar
JBOSS_DIR=${EAP_VERSION}.GA
JBOSS_ZIP=${JBOSS_DIR}.zip

export JBOSS_HOME=jboss-eap-7.4

if [ ! -f "$BASE_ZIP" ] ; then
  echo "Basic distribution $BASE_ZIP not found. https://access.redhat.com/jbossnetwork/restricted/listSoftware.html?product=appplatform&downloadType=distributions&version=7.4"
  exit
fi

if [ ! -f "$PATCH_ZIP" ] ; then
  echo "Patch file $PATCH_ZIP not found. Please download from https://access.redhat.com/jbossnetwork/restricted/listSoftware.html?downloadType=patches&product=appplatform&version=7.4"
  exit
fi

if [ "$EAP_XP_VERSION" != "none" ] && [ ! -f "$XP_PATCH_ZIP" ] ; then
  echo "EAP X patch file $XP_PATCH_ZIP not found. Please download from https://access.redhat.com/jbossnetwork/restricted/listSoftware.html?product=appplatform.xp&downloadType=patches&version=4.0.0"
  exit
fi

if [ "$EAP_XP_VERSION" != "none" ] && [ ! -f "$XP_MANAGER" ] ; then
  echo "EAP X manager $XP_MANAGER not found. Please download from https://access.redhat.com/jbossnetwork/restricted/listSoftware.html?product=appplatform.xp&downloadType=patches&version=4.0.0"
  exit
fi

echo "REMOVING old files..."

find . -type d -depth 1 -name jboss-eap\* -exec rm -rf \{\} \;
rm -f "${JBOSS_DIR}.zip"

echo "EXTRACT $JBOSS_HOME"

unzip -q "$BASE_ZIP"

echo "APPLY Patches for $EAP_VERSION"

$JBOSS_HOME/bin/jboss-cli.sh --echo-command "patch apply $PATCH_ZIP" || exit

if [ "$EAP_XP_VERSION" != "none" ] ; then
  echo "SETUP XP Manager for $EAP_XP_VERSION"
  java -jar "$XP_MANAGER" setup --jboss-home=./jboss-eap-7.4 --accept-support-policy || exit

  echo "APPLY XP Patches for $EAP_XP_VERSION"
  java -jar "$XP_MANAGER" patch-apply --jboss-home=./jboss-eap-7.4 --patch="$XP_PATCH_ZIP" || exit

  JBOSS_ZIP=${JBOSS_DIR}-xp.zip
fi

echo "RENAME folder to ${JBOSS_DIR}"

mv -v "$JBOSS_HOME" "${JBOSS_DIR}" || exit

echo "STRIP ${JBOSS_DIR}"

./strip-patched-jboss.sh "${JBOSS_DIR}"

echo "ZIPPING ${JBOSS_DIR}"

zip -qr "${JBOSS_ZIP}" "${JBOSS_DIR}"

echo "You may now test the built server by running: cd ${JBOSS_DIR}/bin && ./standalone.sh -b 0.0.0.0"
