#!/bin/bash

to_be_installed=""

for i in "$@" ; do
  IFS='=' read -r -a array <<< "$i"

  command=${array[0]}
  package=${array[1]}

  echo "Checking $command -> $package"

  if [ -z "$command" ] ||  [ -z "$package" ] ; then
      echo "Invalid argument $i, should be something like groupadd=shadow-utils"
      exit
  fi

  path=$(command -v "$command")

  if [ -z "$path" ] ; then
    echo "$command -> $package is missing ..."

    to_be_installed="$to_be_installed $package"
  else
    echo "$command found in $path"
  fi
done

if [ -n "$to_be_installed" ] ; then
  echo "Installing packages $to_be_installed ..."

  microdnf update -y
  # shellcheck disable=SC2086
  microdnf install --best --nodocs -y $to_be_installed
  microdnf clean all
fi
