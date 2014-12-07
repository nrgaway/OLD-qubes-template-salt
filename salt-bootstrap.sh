#!/bin/bash -e
# vim: set ts=4 sw=4 sts=4 et :

path="$(readlink -m $0)"
dir="${path%/*}"

source "${dir}/.salt-functions"
source "${dir}/.salt-purge"
source "${dir}/.salt-activate"

# Auto authorize installed salt-minion if AUTHORIZE = "1"
AUTHORIZE=1

# If COPY_REPO="1" then this whole repo will be copied to /srv/salt so the 
# included state files can be updated via git
COPY_REPO=1

# If a file named '.debug' exists in the same directory as 'salt-bootstrap.sh' 
# then salt directories will be deleted before installation and development 
# env will be set up
if [ -f "${dir}/.debug" ]; then
    echo "DEBUG MODE IS ENABLED!"
    DEBUG=1
fi

BUILD_DEPS="vim git ca-certificates lsb-release rsync python-dulwich python-pip"

# -----------------------------------------------------------------------------
# Simulate clean installation (purge all salt related files)
# -----------------------------------------------------------------------------
if [ "$DEBUG" == "1" ] || [ -f "${dir}/.purge" ]; then
    saltPurge
fi

# -----------------------------------------------------------------------------
# Build Depends
# -----------------------------------------------------------------------------
if ! [ -f /tmp/.salt.build_deps ]; then
    RETVAL=0
    if [ "$ID" == "debian" -o "$ID" == "ubuntu" ]; then
        DEBIAN_FRONTEND=noninteractive DEBCONF_NONINTERACTIVE_SEEN=true \
        apt-get --purge -y --force-yes remove salt-minion salt-master salt-syndic

        DEBIAN_FRONTEND=noninteractive DEBCONF_NONINTERACTIVE_SEEN=true \
            apt-get update
        retval $?

        DEBIAN_FRONTEND=noninteractive DEBCONF_NONINTERACTIVE_SEEN=true \
            apt-get -y --force-yes install ${BUILD_DEPS}
        retval $?
    elif [ "$ID" == "fedora" ]; then
        yum erase -y salt
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
"${dir}/salt/files/bind-directories" \
    /usr/bin/python:/usr/local/bin/python \
    /rw/usrlocal/srv/salt:/srv/salt \
    /rw/usrlocal/srv/pillar:/srv/pillar \
    /rw/usrlocal/etc/salt:/etc/salt \
    /rw/usrlocal/var/cache/salt:/var/cache/salt

# -----------------------------------------------------------------------------
# Install modified salt-* unit files
# -----------------------------------------------------------------------------
systemctl stop salt-api salt-minion salt-syndic salt-master || true
systemctl disable salt-api salt-minion salt-syndic salt-master || true

install --owner=root --group=root --mode=0644 "${dir}/salt/files/salt-master.service" /etc/systemd/system
install --owner=root --group=root --mode=0644 "${dir}/salt/files/salt-minion.service" /etc/systemd/system
install --owner=root --group=root --mode=0644 "${dir}/salt/files/salt-syndic.service" /etc/systemd/system
install --owner=root --group=root --mode=0644 "${dir}/salt/files/salt-api.service" /etc/systemd/system

install -d --owner=root --group=root --mode=0750 /etc/salt
install --owner=root --group=root --mode=0640 "${dir}/salt/files/master" /etc/salt
install --owner=root --group=root --mode=0640 "${dir}/salt/files/minion" /etc/salt
install -d --owner=root --group=root --mode=0750 /etc/salt/master.d
install -d --owner=root --group=root --mode=0750 /etc/salt/minion.d
install --owner=root --group=root --mode=0640 "${dir}/salt/files/master.d/"* /etc/salt/master.d || true
install --owner=root --group=root --mode=0640 "${dir}/salt/files/minion.d/"* /etc/salt/minion.d || true

install -d --owner=root --group=root --mode=0750 /srv/salt
install -d --owner=root --group=root --mode=0750 /srv/pillar
install -d --owner=root --group=root --mode=0750 /srv/salt-formulas

if [ "$COPY_REPO" == "1" ]; then
    cp -r "${dir}/". /srv/salt

    # Don't allow .debug or .purge files to copy over
    rm -f /srv/salt/.debug
    rm -f /srv/salt/.purge
else
    install --owner=root --group=root --mode=0640 "${dir}/top.sls" /srv/salt/top.sls
    cp -r "${dir}/salt" /srv/salt/salt || true
    cp -r "${dir}/python_pip" /srv/salt/python_pip || true
    cp -r "${dir}/vim" /srv/salt/vim || true
    cp -r "${dir}/theme" /srv/salt/theme || true
fi
cp -r "${dir}/pillar/"* /srv/pillar || true

# Replace master config files with development files
if [ "$DEBUG" == "1" ] && [ -d "${dir}/dev" ]; then
    pushd "${dir}/dev"
        ./dev-mode.sh
    popd
fi

chmod -R u=rwX,g=rX,o-wrxX /srv/salt
chmod -R u=rwX,g=rX,o-wrxX /srv/pillar
sync

systemctl enable salt-master salt-minion salt-api
systemctl start salt-master salt-minion salt-api

salt-call --local saltutil.sync_all
salt-call --local state.highstate -l debug || true
timer 5
sync

# Salt was replaced, so safely restart it
echo
echo "Since salt was replaced, salt-master and salt-minion will be stopped,"
echo "disabled, re-enabled and then restarted."
echo
echo "NOTE: It can take salt-master a long time to stop (1 to 2 minutes)"
echo "without any indication of its progress.  Be patient :)"
echo
systemctl stop salt-minion || true
systemctl stop salt-master || true

systemctl disable salt-master || true
systemctl disable salt-minion || true

systemctl enable salt-master || true
systemctl enable salt-minion || true

systemctl start salt-master || true
systemctl start salt-minion || true

# Just incase we have not yet authorized...
if [ "$AUTHORIZE" == "1" ]; then
    echo "Trying to authorize minion..."
    timer 30
    saltActivate
fi
