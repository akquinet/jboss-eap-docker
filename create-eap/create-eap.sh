#!/bin/bash

if [ -z "$1" ] ; then
	echo "Usage: $0 <EAP-Version>, e.g. $0 jboss-eap-7.4.16"
	exit
else
	EAP_VERSION=$1
fi

JBOSS_DIR=${EAP_VERSION}.GA

unzip jboss-eap-7.4.0.zip

cd jboss-eap-7.4 || exit

echo APPLY Patch

bin/jboss-cli.sh --echo-command "patch apply ../${EAP_VERSION}-patch.zip"

echo RENAME to ${JBOSS_DIR}

cd ..
mv jboss-eap-7.4 ${JBOSS_DIR}

echo STRIP ${JBOSS_DIR}

./strip-patched-jboss.sh ${JBOSS_DIR}

zip -r ${JBOSS_DIR}.zip ${JBOSS_DIR}

echo TEST built server ...

cd "${JBOSS_DIR}/bin" || exit

./standalone.sh -c standalone-full.xml
