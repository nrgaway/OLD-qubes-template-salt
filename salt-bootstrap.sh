#!/bin/bash -e
# vim: set ts=4 sw=4 sts=4 et :

# If DEBUG="1" then salt directories will be deleted before installation
DEBUG=1

INSTALLDIR=/

BUILD_DEPS="vim git ca-certificates lsb-release rsync python-dulwich python-pip"

retval() {
    local ret_val=$1
    if ! [ $ret_val == 0 ]; then
        $RETVAL=1
    fi
}

function systemctl() {
    action=$1
    shift

    for unit in $@; do
        echo "systemctl $action $unit"
        /usr/bin/systemctl $action $unit || true
    done
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
# Simulate clean installation
# -----------------------------------------------------------------------------
if [ "$DEBUG" == "1" ]; then
    systemctl stop salt-api salt-minion salt-syndic salt-master
    systemctl disable salt-api salt-minion salt-syndic salt-master
    rm -rf /rw/usrlocal/srv/*
    rm -rf /rw/usrlocal/etc/salt/*
    rm -rf /etc/salt/*
    rm -rf /srv/salt/*
    rm -rf /srv/salt-formulas/*
    rm -rf /srv/pillar/*
    rm -rf /var/cache/salt
    rm -rf /root/src/salt
    rm -rf /lib/systemd/system/salt-*
    rm -rf /etc/systemd/system/salt-*
    rm -rf /tmp/salt-bootstrap
    rm -rf /etc/pki/minion
    rm -f /etc/pki/tls/certs/localhost.*
    rm -f /tmp/.salt*
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

    # XXX: Specify a specific tag so we don't run into regrerssion errors
    # XXX: Need to verify git signatures

    if [ ! -d /tmp/salt-bootstrap ]; then
        git clone https://github.com/saltstack/salt-bootstrap.git /tmp/salt-bootstrap
    fi

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

    pushd /tmp/salt-bootstrap
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
install --owner=root --group=root --mode=0755 salt/files/bind-directories /rw/usrlocal/bin
/rw/usrlocal/bin/bind-directories /rw/usrlocal/srv/salt:/srv/salt /rw/usrlocal/srv/pillar:/srv/pillar /rw/usrlocal/etc/salt:/etc/salt

# -----------------------------------------------------------------------------
# Install modified salt-* unit files
# -----------------------------------------------------------------------------
systemctl stop salt-api salt-minion salt-syndic salt-master || true
systemctl disable salt-api salt-minion salt-syndic salt-master || true

install --owner=root --group=root --mode=0644 salt/files/salt-master.service /etc/systemd/system
install --owner=root --group=root --mode=0644 salt/files/salt-minion.service /etc/systemd/system
install --owner=root --group=root --mode=0644 salt/files/salt-syndic.service /etc/systemd/system
install --owner=root --group=root --mode=0644 salt/files/salt-api.service /etc/systemd/system

install -d --owner=root --group=root --mode=0750 /etc/salt
install --owner=root --group=root --mode=0640 salt/files/master /etc/salt
install --owner=root --group=root --mode=0640 salt/files/minion /etc/salt
install -d --owner=root --group=root --mode=0750 /etc/salt/master.d
install -d --owner=root --group=root --mode=0750 /etc/salt/minion.d
install --owner=root --group=root --mode=0640 salt/files/master.d/* /etc/salt/master.d || true
install --owner=root --group=root --mode=0640 salt/files/minion.d/* /etc/salt/minion.d || true

install -d --owner=root --group=root --mode=0750 /srv/salt
install -d --owner=root --group=root --mode=0750 /srv/pillar
install -d --owner=root --group=root --mode=0750 /srv/salt-formulas

install --owner=root --group=root --mode=0640 top.sls /srv/salt/top.sls

cp -r pillar/* /srv/pillar || true
cp -r salt /srv/salt/salt || true
cp -r python_pip /srv/salt/python_pip || true
cp -r vim /srv/salt/vim || true

chmod -R u=rwX,g=rX,o-wrxX /srv/salt
chmod -R u=rwX,g=rX,o-wrxX /srv/pillar
sync

systemctl enable salt-master salt-minion salt-api
systemctl start salt-master salt-minion salt-api

# Give time for minion to be authorized
echo "Sleeping for 15 seconds..."
sleep 15

# Instead of auto-accepting minions; just do it here
salt-key -y -A
systemctl restart salt-master salt-minion || true
sleep 10

salt-call --local saltutil.sync_all
salt-call --local state.highstate -l debug || true

echo "Sleeping for 5 seconds..."
sync
systemctl restart salt-master salt-minion || true
