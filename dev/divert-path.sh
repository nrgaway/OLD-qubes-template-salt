#!/bin/bash -e
# vim: set ts=4 sw=4 sts=4 et :

sudo cp -rp /home/user/.wingide5 /root/
sudo /rw/usrlocal/bin/bind-directories /rw/root/.wingide5:/root/.wingide5

pushd /home/user/dockernas/srv/salt-formulas/yamlscript-formula/src
    sudo ./wing-debug-setup.sh
popd
