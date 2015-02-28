__author__ = 'root'

#
# This module is only used with WingIDE debugger for testing code within
# The debugging environment
#
# Add command line options in wing like:
# --local state.highstate

import sys
import subprocess

from salt.scripts import salt_call

SYNC = False

if __name__ == '__main__':
    argv = sys.argv

    # Soft link the pyc so we can set breakpoints on it
    # NOTE:
    # If source file is changed, salt will regenerate pyc on first call, so we will not
    # be able to use breakpoints till second call.  Better than nothing though fo now
    #
    # This is because if salt detects pyc is stale, it regenerates pyc AND remove soft
    # link in doing so.  I have not figured out a way to force soft links to be non delete-able

    #cmd = "ln -sf /srv/salt-formulas/yamlscript-formula/src/yamlscript.pyc /root/src/salt/salt/renderers/"
    #subprocess.call(cmd.split())

    # Sync renderers first
    if SYNC:
        subprocess.call(['sudo', 'salt-call', '--local', 'saltutil.sync_all'])

    salt_call()
