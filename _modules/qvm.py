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


# Used to identify values that have not been passed to functions which allows
# the function modules not to have to know anything about the default types
# excpected
try:
    if MARKER:
        pass
except NameError:
    MARKER = object()


# XXX: Not yet used
def _get_fnargs(function, **kwargs):
    args, fnargs = salt.utils.arg_lookup(function).values()
    for key, value in kwargs.items():
        if key in fnargs:
            fnargs[key] = value
    return fnargs


def _get_vm(vmname):
    qvm_collection = QubesVmCollection()
    qvm_collection.lock_db_for_reading()
    qvm_collection.load()
    qvm_collection.unlock_db()
    vm = qvm_collection.get_vm_by_name(vmname)
    if not vm or vm.qid not in qvm_collection:
        return None
    return vm


def _run_all(cmd):
    if isinstance(cmd, list):
        cmd = ' '.join(cmd)

    result = __salt__['cmd.run_all'](cmd, runas='user', output_loglevel='quiet')
    result.pop('pid', None)
    return result


def check(vmname):
    '''
    Check if a virtual machine exists::

    CLI Example:

    .. code-block:: bash

        salt '*' qvm.check <vm-name>
    '''
    cmd = "/usr/bin/qvm-check {0}".format(vmname)
    return _run_all(cmd)


def state(vmname):
    '''
    Return virtual machine state::

    CLI Example:

    .. code-block:: bash

        salt '*' qvm.state <vm-name>
    '''
    ret = {}

    vm = _get_vm(vmname)
    if not vm:
        return check(vmname)

    ret['stdout'] = vm.get_power_state()
    ret['retcode'] = not vm.is_guid_running()
    return ret


def create(vmname,
           template=None,
           label=None,
           proxy=None,
           hvm=None,
           hvm_template=None,
           net=None,
           standalone=None,
           root_move_from=None,
           root_copy_from=None,
           mem=None,
           vcpus=None,
           internal=None):
    '''
    Create a new virtual machine::

    CLI Example:

    .. code-block:: bash

        salt '*' qvm.create <vm-name> label=red template=fedora-20-x64
    '''
    # Check if an existing VM already exists with same name and fail if so
    ret = check(vmname)
    if not ret['retcode']:
        ret['retcode'] = 1
        return ret

    cmd = ['/usr/bin/qvm-create']
    args, fnargs = salt.utils.arg_lookup(create).values()
    for arg in fnargs:
        value = locals().get(arg, None)
        if value:
            arg = '--' + arg.replace('_', '-')
            cmd.extend([arg, str(value)])
    cmd.append(vmname)

    ret = _run_all(cmd)
    return ret


# TODO Test salt CLI docs
def remove(vmname, just_db=None):
    '''
    Remove an existing virtual machine::

    CLI Example:

    .. code-block:: bash

        salt '*' qvm.remove <vm-name> [just_db=True]
    '''
    # Make sure the VM exists, otherwise fail
    ret = check(vmname)
    if ret['retcode']:
        return ret

    cmd = ['/usr/bin/qvm-remove']
    args, fnargs = salt.utils.arg_lookup(remove).values()
    for arg in fnargs:
        value = locals().get(arg, None)
        if value:
            arg = '--' + arg.replace('_', '-')
            cmd.extend([arg, str(value)])
    cmd.append(vmname)

    ret = _run_all(cmd)
    return ret


def clone(vmname,
          target,
          label=None,
          path=None):
    '''
    Clone a new virtual machine::

    CLI Example:

    .. code-block:: bash

        salt '*' qvm.clone <vm-name> <target_name> [path=]
    '''
    # Check if an existing VM already exists with same name and fail if so
    ret = check(target)
    if not ret['retcode']:
        ret['retcode'] = 1
        return ret

    cmd = ['/usr/bin/qvm-clone']
    args, fnargs = salt.utils.arg_lookup(create).values()
    for arg in fnargs:
        value = locals().get(arg, None)
        if value:
            arg = '--' + arg.replace('_', '-')
            cmd.extend([arg, str(value)])
    cmd.append(vmname)
    cmd.append(target)

    ret = _run_all(cmd)
    return ret


def _get_prefs(vmname):
    '''
    Return the current preferences for vmname::

    CLI Example:

    .. code-block:: bash

        salt '*' qvm.get_prefs <vm-name>
    '''
    vm = _get_vm(vmname)
    if not vm:
        return {}

    ret = {}
    args, prefs = salt.utils.arg_lookup(__salt__['qvm.prefs']).values()
    for key in prefs:
        value = getattr(vm, key, None)
        value = getattr(value, 'name', value)
        ret[key] = value
    return ret


def prefs(vmname,
          include_in_backups=MARKER,
          pcidevs=MARKER,
          label=MARKER,
          netvm=MARKER,
          maxmem=MARKER,
          memory=MARKER,
          kernel=MARKER,
          template=MARKER,
          vcpus=MARKER,
          kernelopts=MARKER,
          name=MARKER,
          drive=MARKER,
          mac=MARKER,
          debug=MARKER,
          default_user=MARKER,
          qrexec_installed=MARKER,
          guiagent_installed=MARKER,
          seamless_gui_mode=MARKER,
          qrexec_timeout=MARKER,
          timezone=MARKER,
          internal=MARKER,
          autostart=MARKER):
    '''
    Set preferences for vm target

    CLI Example:

    .. code-block:: bash

        salt '*' qvm.set_prefs <vm_name> label=orange

    Calls the qubes utility directly since the currently library really has
    no validation routines whereas the script does.
    '''
    ret = {'retcode': 0,
           'changes': {},}
    stdout = stderr = ''

    # Get only values passed to function and not the same as in current_state
    current_state =  _get_prefs(vmname)
    data = dict([(key, value) for key, value in locals().items() if key in current_state and value != MARKER])

    if not data:
        return current_state
    else:
        data = dict([(key, value) for key, value in data.items() if value != current_state[key]])

    if data:
        for key, value in data.items():
            cmd = "/usr/bin/qvm-prefs {0} -s {1} {2}".format(vmname, key, value)
            result = __salt__['cmd.run_all'](cmd, runas='user')

            if result['retcode']:
                ret['retcode'] = result['retcode']
                stderr += '{0}: {1}\n{2}'.format(key, value, result['stderr'])
            else:
                ret['changes'][key] = {}
                ret['changes'][key]['old'] = current_state[key]
                ret['changes'][key]['new'] = value
                stdout += result['stdout'] + '\n'
    else:
        stdout = 'Preferences for {0} are already in desired state!'.format(vmname)

    if stderr:
        ret['stdout'] = stderr
    else:
        ret['stdout'] = stdout
    return ret
