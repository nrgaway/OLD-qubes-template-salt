#!/bin/bash -e
# vim: set ts=4 sw=4 sts=4 et :

INSTALLDIR=/

BUILD_DEPS="vim git ca-certificates lsb-release rsync python-dulwich"

retval() {
    local ret_val=$1
    if ! [ $ret_val == 0 ]; then
        $RETVAL=1
    fi
}

## Determine OS version
if [ -f "/etc/os-release" ]; then
    source /etc/os-release
else
    echo "/etc/os-release file does not exist so can not determine OS type"
    echo "Exiting..."
    exit 1
fi

# -----------------------------------------------------------------------------
# Build Depends
# -----------------------------------------------------------------------------
if ! [ -f /tmp/.salt.build_deps ]; then
    RETVAL=0
    if [ "$ID" == "debian" -o "$ID" == "ubuntu" ]; then
        DEBIAN_FRONTEND=noninteractive DEBCONF_NONINTERACTIVE_SEEN=true \
            chroot "${INSTALLDIR}" apt-get update
        retval $?

        DEBIAN_FRONTEND=noninteractive DEBCONF_NONINTERACTIVE_SEEN=true \
            chroot "${INSTALLDIR}" apt-get -y --force-yes install ${BUILD_DEPS}
        retval $?
    elif [ "$ID" == "fedora" ]; then
        yum install -y ${BUILD_DEPS}
        retval $?
    else
        echo "Exiting Build and Installation of salt"
        echo "The operating system id is listed as: $id"
        echo "And this script has only been tested to work on fedora, debian or ubuntu"
        exit 1
    fi

    if [ $RETVAL == 0 ]; then
        touch /tmp/.salt.build_deps
    fi
fi

# -----------------------------------------------------------------------------
# Clone salt bootstrap
# -----------------------------------------------------------------------------
if [ /tmp/.salt.build_deps -a ! -f /tmp/.salt.cloned ]; then
    RETVAL=0

    git clone https://github.com/saltstack/salt-bootstrap.git

    retval $?
    if [ $RETVAL == 0 ]; then
        touch /tmp/.salt.cloned
    fi
fi

# -----------------------------------------------------------------------------
# Install salt via bootstrap
#
#  install.sh options:
#  -D  Show debug output.
#  -X  Do not start daemons after installation
#  -U  If set, fully upgrade the system prior to bootstrapping salt
#  -M  Also install salt-master
#  -S  Also install salt-syndic
#  -N  Do not install salt-minion
#  -p  Extra-package to install while installing salt dependencies. One package
#      per -p flag. You're responsible for providing the proper package name.
#
#======================================================================================================================
#  Environment variables taken into account.
#----------------------------------------------------------------------------------------------------------------------
#   * BS_COLORS:                If 0 disables colour support
#   * BS_PIP_ALLOWED:           If 1 enable pip based installations(if needed)
#   * BS_ECHO_DEBUG:            If 1 enable debug echo which can also be set by -D
#   * BS_SALT_ETC_DIR:          Defaults to /etc/salt (Only tweak'able on git based installations)
#   * BS_KEEP_TEMP_FILES:       If 1, don't move temporary files, instead copy them
#   * BS_FORCE_OVERWRITE:       Force overriding copied files(config, init.d, etc)
#   * BS_UPGRADE_SYS:           If 1 and an option, upgrade system. Default 0.
#   * BS_GENTOO_USE_BINHOST:    If 1 add `--getbinpkg` to gentoo's emerge
#   * BS_SALT_MASTER_ADDRESS:   The IP or DNS name of the salt-master the minion should connect to
#   * BS_SALT_GIT_CHECKOUT_DIR: The directory where to clone Salt on git installations
#======================================================================================================================

# -----------------------------------------------------------------------------
if [ /tmp/.salt.cloned -a ! -f /tmp/.salt.bootstrap ]; then
    RETVAL=0

    pushd salt-bootstrap
    ./bootstrap-salt.sh -D -U -X -M git v2014.7.0
    retval $?
    popd

    if [ $RETVAL == 0 ]; then
        touch /tmp/.salt.bootstrap
    fi
fi

# -----------------------------------------------------------------------------
# Bind /rw dirs to salt dirs
# -----------------------------------------------------------------------------
install --owner=root --group=root --mode=0755 files/salt/salt/files/bind-directories /rw/usrlocal/bin
/rw/usrlocal/bin/bind-directories /rw/usrlocal/srv/salt:/srv/salt /rw/usrlocal/srv/pillar:/srv/pillar /rw/usrlocal/etc/salt:/etc/salt

# -----------------------------------------------------------------------------
# Install modified salt-* unit files
# -----------------------------------------------------------------------------
function systemctl() {
    action=$1
    shift

    for unit in $@; do
        /usr/bin/systemctl $action $unit
    done
}

systemctl stop salt-api salt-minion salt-syndic salt-master
systemctl disable salt-api salt-minion salt-syndic salt-master

install --owner=root --group=root --mode=0644 files/salt/salt/files/salt-master.service /etc/systemd/system
install --owner=root --group=root --mode=0644 files/salt/salt/files/salt-minion.service /etc/systemd/system
install --owner=root --group=root --mode=0644 files/salt/salt/files/salt-syndic.service /etc/systemd/system
install --owner=root --group=root --mode=0644 files/salt/salt/files/salt-api.service /etc/systemd/system

install --owner=root --group=root --mode=0640 files/salt/salt/files/master /etc/salt
install --owner=root --group=root --mode=0640 files/salt/salt/files/minion /etc/salt
install -d --owner=root --group=root --mode=0750 /etc/salt/master.d
install -d --owner=root --group=root --mode=0750 /etc/salt/minion.d
install --owner=root --group=root --mode=0640 files/salt/salt/files/master.d/* /etc/salt/master.d || true
install --owner=root --group=root --mode=0640 files/salt/salt/files/minion.d/* /etc/salt/minion.d || true

install -d --owner=root --group=root --mode=0750 /srv/salt
install -d --owner=root --group=root --mode=0750 /srv/pillar
install -d --owner=root --group=root --mode=0750 /srv/salt-formulas

#install --owner=root --group=root --mode=0640 files/salt/* /srv/salt || true
#install --owner=root --group=root --mode=0640 files/pillar/* /srv/pillar || true
cp -r files/salt/* /srv/salt || true
cp -r files/pillar/* /srv/pillar || true
chmod -R u=rwX,g=rX,o-wrxX /srv/salt
chmod -R u=rwX,g=rX,o-wrxX /srv/pillar

ln -sf /var/cache/salt/minion/files/base /srv/formulas

systemctl enable salt-master salt-minion salt-api
systemctl start salt-master salt-minion salt-api

# Give time for minion to be authorized
echo "Sleeping for 15 seconds..."
sleep 15

# Instead of auto-accepting minions; just do it here
#salt-key -y -A

#salt '*' state.highstate -l debug
