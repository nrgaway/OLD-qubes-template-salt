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
    - salt.gitfs
    - salt.api
    - salt.syndic_absent
    - salt.halite
    #
    #- salt.api_absent
    #- salt.master_absent
    #- salt.syndic
    #
    #- vim
    #- vim.salt
