#!/bin/bash -e

if [ ! $RELEASE ]; then
	RELEASE='jammy'
fi

./mk-rootfs-$RELEASE.sh
