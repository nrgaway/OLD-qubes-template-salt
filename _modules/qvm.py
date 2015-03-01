# -*- coding: utf-8 -*-
'''
Manage Qubes settings
'''

# Import python libs
import os
import subprocess
import logging

# Import salt libs
import salt.utils
from salt.utils import which as _which
from salt.exceptions import (
    CommandExecutionError, SaltInvocationError
)

# Import Qubes libs
from qubes.qubes import QubesVmCollection

log = logging.getLogger(__name__)

# Define the module's virtual name
__virtualname__ = 'qvm'

def __virtual__():
    '''
    Confine this module to Qubes dom0 based systems
    '''
    try:
        virtual_grain = __grains__['virtual'].lower()
        virtual_subtype = __grains__['virtual_subtype'].lower()
    except Exception:
        return False

    enabled = ('xen dom0')
    if virtual_grain == 'qubes' or virtual_subtype in enabled:
        return __virtualname__
    return False

#__outputter__ = {
#    'get_prefs': 'txt',
#}

_prefs = [
    "include_in_backups",
    "pcidevs",
    "label",
    "netvm",
    "maxmem",
    "memory",
    "kernel",
    "template",
    "vcpus",
    "kernelopts",
    "name",
    "drive",
    "mac",
    "debug",
    "default_user",
    "qrexec_installed",
    "guiagent_installed",
    "seamless_gui_mode",
    "qrexec_timeout",
    "timezone",
    "internal",
    "autostart",
]

def get_prefs(vmname):
    '''
    Return the preferences for vmname::

        {'key': 'value'}

    CLI Example:

    .. code-block:: bash

        salt '*' qvm.get_prefs
    '''
    qvm_collection = QubesVmCollection()
    qvm_collection.lock_db_for_reading()
    qvm_collection.load()
    qvm_collection.unlock_db()

    vm = qvm_collection.get_vm_by_name(vmname)
    if vm is None or vm.qid not in qvm_collection:
        return {}

    ret = {}
    for key in _prefs:
        value = getattr(vm, key, None)
        value = getattr(value, 'name', value)
        ret[key] = value
    return ret


def set_prefs(vmname, data):
    '''
    Set preferences for vm target

    CLI Example:

    .. code-block:: bash

        salt '*' qvm.set_prefs vm_name value

    Calls the qubes utility directly since the currently library really has
    no validation routines whereas the script does.
    '''

    ret = {'retcode': 0,
           'changes': {},
           'comment': ''}

    for key, value in data.items():
        cmd = "/usr/bin/qvm-prefs {0} -s {1} {2}".format(vmname, key, value)
        result = __salt__['cmd.run_all'](cmd, runas='user')

        if result['retcode']:
            ret['retcode'] = result['retcode']
            ret['comment'] += '{0}: {1}\n{2}'.format(key, value, result['stderr'])
        else:
            ret['changes'][key] = {}
            ret['changes'][key]['new'] = value
            ret['comment'] += result['stdout'] + '\n'

    return ret
