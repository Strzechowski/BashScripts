#!/usr/bin/env bash

traverse() {
# $1 --- path to be traversed
# $2 --- spaces to print before filenames

list="$(ls $1 --file-type)"

for i in ${list}; do 
  if [[ $i =~ /$ ]] ; then
    #removing the '/' at the end of directory
    echo "${2}Directory: ${i: : -1}"
    traverse "${1}/${i}" "${2}    "
  else 
    echo "${2}File: ${i}"
  fi
done
}

traverse . ""
