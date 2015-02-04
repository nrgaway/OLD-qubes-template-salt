#
# salt-call --local state.highstate
# salt '*' state.highstate -l debug
#

base:
  '*':
    - python_pip
    - salt
    - salt.minion
    - salt.master
    - salt.api
    # salt.gitfs
    # salt.syndic
    # salt.halite
    # salt.api_absent
    # salt.master_absent
    - salt.syndic_absent
    - salt.halite_absent
    - vim
    - users
    - theme
    - theme.fonts_ubuntu
    - theme.fonts_source_code_pro
    # --- development ---
    - salt.gitfs_dev
    - nginx
    - nginx.common
    - nginx.package
    - nginx.users
    - jenkins

