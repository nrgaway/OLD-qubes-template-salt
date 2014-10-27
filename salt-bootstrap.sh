#!/bin/bash -e
# vim: set ts=4 sw=4 sts=4 et :

INSTALLDIR=/

BUILD_DEPS="vim git ca-certificates lsb-release"

retval() {
    local ret_val=$1
    if ! [ $ret_val == 0 ]; then
        $RETVAL=1
    fi
}

# -----------------------------------------------------------------------------
# Build Depends
# -----------------------------------------------------------------------------
if ! [ -f /tmp/.salt.build_deps ]; then
    RETVAL=0

    DEBIAN_FRONTEND=noninteractive DEBCONF_NONINTERACTIVE_SEEN=true \
        chroot "${INSTALLDIR}" apt-get update
    retval $?

    DEBIAN_FRONTEND=noninteractive DEBCONF_NONINTERACTIVE_SEEN=true \
        chroot "${INSTALLDIR}" apt-get -y --force-yes install ${BUILD_DEPS}
    retval $?

    if [ $RETVAL == 0 ]; then
        touch /tmp/.salt.build_deps
    fi
fi

# -----------------------------------------------------------------------------
# Clone salt bootstrap
# -----------------------------------------------------------------------------
if ! [ -f /tmp/.salt.cloned ]; then
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
if ! [ -f /tmp/.salt.bootstrap ]; then
    RETVAL=0

    pushd salt-bootstrap
    ./bootstrap-salt.sh -D -U -X -M git v2014.7.0rc6
    retval $?
    popd

    if [ $RETVAL == 0 ]; then
        touch /tmp/.salt.bootstrap
    fi
fi
