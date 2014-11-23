#
# salt-call --local state.highstate
# salt '*' state.highstate -l debug
#

base:
  '*':
    - python_pip
    - salt.minion
    - salt.master
    - salt.halite
    - salt.gitfs
    - vim
    - vim.salt
