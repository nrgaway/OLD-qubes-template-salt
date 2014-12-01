#!/bin/bash -e
# vim: set ts=4 sw=4 sts=4 et :

# dev-mode.sh will be called before running final salt states so 
# environments can be set up or whatever

# Replace master config files with development files
if [ -f gitfs-test.conf ]; then
    sudo cp -f gitfs-test.conf /srv/salt/salt/files/master.d/gitfs.conf
elif [ -f gitfs.conf ]; then
    sudo cp -f gitfs.conf /srv/salt/salt/files/master.d/gitfs.conf
fi
