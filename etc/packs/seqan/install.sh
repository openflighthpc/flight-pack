#!/bin/bash
set -euxo pipefail

d="$1"
archive="${flight_PACK_store_dir}/spack+seqan.tar.bz2"
# XXX - rework this to ensure we're extracting into the right area
# based on the current flight env configuration!
target_root="${flight_ROOT}"/var/lib/env

if [ -e "${archive}" ]; then
    exit 0
    if [ -d "${target_root}"/spack+seqan ]; then
	pack_err "Packaged environment already exists: ${target_root}/spack+seqan"
	exit 1
    else
	pack_stage "Extracting packaged environment"
	mkdir -p "${target_root}"
	cd "${target_root}"
	# XXX - it would be nice to display a progress bar
	tar xjf ${archive}
    fi
else
    echo "Packaged environment not found: ${archive}"
    pack_err "Packaged environment not found: ${archive}"
    exit 1
fi
