#
# First Run only: sync any modules, etc
# salt-call --local saltutil.sync_all
#
# Highstate will execute all states
# salt-call --local state.highstate
#

base:
  '*':
    # python_pip
    # salt
    # salt.minion
    # salt.master
    # salt.api
    # salt.gitfs
    # salt.syndic
    # salt.halite
    # salt.api_absent
    # salt.master_absent
    # salt.syndic_absent
    # salt.halite_absent

    # vim
    - dom0

    # users
    # theme
    # theme.fonts_ubuntu
    # theme.fonts_source_code_pro
    # --- development ---
    # salt.gitfs_dev
    # nginx
    # nginx.common
    # nginx.package
    # nginx.users
    # jenkins

