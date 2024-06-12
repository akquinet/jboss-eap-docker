#!/usr/bin/env bash

if [ -z "$1" ] ; then
	echo "Usage: $0 <EAP-Version>, e.g. $0 jboss-eap-7.4.16.GA"
	exit
else
	JBOSS_DIR=$1
fi

if [ ! -x "$JBOSS_DIR" ] ; then
	echo "$JBOSS_DIR does not exist"
	exit
fi

INSTALLATION_DIR="$JBOSS_DIR/.installation"
LAYERS_CONF="$JBOSS_DIR/modules/layers.conf"

MODULE_BASE_DIR="$JBOSS_DIR/modules/system/layers/base"
MICROPROFILE_BASE_DIR="$JBOSS_DIR/modules/system/layers/microprofile"
BUNDLE_BASE_DIR="$JBOSS_DIR/bundles/system/layers/base"
MARKER=XXX_DELETEME

DIRS=()

if [ -x "$MODULE_BASE_DIR" ] ; then
  DIRS+=("$MODULE_BASE_DIR")
fi

if [ -x "$MICROPROFILE_BASE_DIR" ] ; then
  DIRS+=("$MICROPROFILE_BASE_DIR")
fi

if [ -x "$BUNDLE_BASE_DIR" ] ; then
  DIRS+=("$BUNDLE_BASE_DIR")
fi

echo "********** Stripping $JBOSS_DIR with detected module paths ${DIRS[*]} ... **********"

if [ -x "$LAYERS_CONF" ] ; then
	mv "$LAYERS_CONF" "$LAYERS_CONF_DIR$MARKER"
fi

if [ -x "$INSTALLATION_DIR" ] ; then
	mv "$INSTALLATION_DIR" "$INSTALLATION_DIR$MARKER"
fi

for dir in "${DIRS[@]}" ; do
  current_version=$(cat "$dir/.overlays/.overlays")
	current_modules_dir=$dir/.overlays/$current_version

  echo "********** Current modules directory is $current_modules_dir **********"

#  read -r -p "Continue (y/n)?"

	# shellcheck disable=SC2044
	for patchmoduledir in $(find "$current_modules_dir" -name module.xml); do
		relative_path=${patchmoduledir#"${current_modules_dir}/"}
		relative_path=${relative_path%/module.xml}
		old_module=$dir/$relative_path
		patched_module=$current_modules_dir/$relative_path
		
		if [ -x "$old_module" ] ; then
			if [ ! -x "$patched_module" ] ; then
				echo "Patched module directory $patched_module does not exist. GIVING UP!!"
				exit
			fi

			mv "$old_module" "${old_module}$MARKER"
		else
			echo "WARNING: Module directory $old_module does not exist. Will be created."
			mkdir -p "${old_module%/main}"
		fi
		
		echo "Replacing $old_module with contents of $patched_module"
		
		cp -r "$patched_module" "$old_module"
	done
	
	mv "$dir/.overlays" "$dir/OVERLAYS$MARKER"
done

echo "********** Cleaning up overlay files **********"

delete=$(find "$JBOSS_DIR" -name \*"$MARKER")

# shellcheck disable=SC2086
rm -rf $delete

chmod 755 "$JBOSS_DIR"/bin/*.sh
rm -rf "$JBOSS_DIR/standalone/log" "$JBOSS_DIR/standalone/tmp" "$JBOSS_DIR/standalone/data"