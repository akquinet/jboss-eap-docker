#!/usr/bin/env bash

if [ -z "$1" ] ; then
	echo "Usage: $0 <EAP-Version>, e.g. $0 jboss-eap-7.4.16.GA"
	exit
else
	JBOSS_DIR=$1
fi

INSTALLATION_DIR="$JBOSS_DIR/.installation"
BUNDLE_BASE_DIR="$JBOSS_DIR/bundles/system/layers/base"
MODULE_BASE_DIR="$JBOSS_DIR/modules/system/layers/base"
CURRENT_VERSION=$(cat "$MODULE_BASE_DIR/.overlays/.overlays")

echo "Stripping $JBOSS_DIR ..."

DIRS[0]=$MODULE_BASE_DIR

if [ -x "$BUNDLE_BASE_DIR" ] ; then
	DIRS[1]=$BUNDLE_BASE_DIR
fi

if [ ! -x "$JBOSS_DIR" ] ; then
	echo "$JBOSS_DIR does not exist"
	exit
fi

echo "Current Version is $CURRENT_VERSION"

if [ -x "$INSTALLATION_DIR" ] ; then
	echo "Remove installation directory $INSTALLATION_DIR"
	mv "$INSTALLATION_DIR" "$INSTALLATION_DIR"XXX_DELETEME
fi

for dir in "${DIRS[@]}" ; do
	current_modules_dir=$dir/.overlays/$CURRENT_VERSION

	# shellcheck disable=SC2044
	for patchmoduledir in $(find "$current_modules_dir" -name module.xml); do
		relative_path=${patchmoduledir#"${current_modules_dir}/"}
		relative_path=${relative_path%/module.xml}
		old_module=$dir/$relative_path
		patched_module=$current_modules_dir/$relative_path
		
		if [ -x "$old_module" ] ; then
			if [ ! -x "$patched_module" ] ; then
				echo "Patched module directory $patched_module does not exist. GIVING UP"
				exit
			fi

			mv "$old_module" "${old_module}XXX_DELETEME"
		else
			echo "WARNING: Module directory $old_module does not exist. Will be CREATED"
			mkdir -p "${old_module%/main}"
		fi
		
		echo "Replace $old_module with contents of $patched_module"
		
		cp -r "$patched_module" "$old_module"
	done
	
	echo Cleaning up overlays
	mv "$dir/.overlays" "$dir/OVERLAYSXXX_DELETEME"
done

echo Cleaning up files
rm -r $(find "$JBOSS_DIR" -name \*XXX_DELETEME)
chmod 755 "$JBOSS_DIR"/bin/*.sh
rm -rf "$JBOSS_DIR/standalone/log" "$JBOSS_DIR/standalone/tmp" "$JBOSS_DIR/standalone/data"