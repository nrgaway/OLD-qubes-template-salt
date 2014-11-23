#
# salt-call --local state.highstate
#

base:
  '*':
    #- python_pip
    #- salt.minion
    #- salt.master
    #- salt.halite
    - vim
    - vim.salt
