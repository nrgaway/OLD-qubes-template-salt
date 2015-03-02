# -*- coding: utf-8 -*-
'''
:maintainer:    Jason Mehring <nrgaway@gmail.com>
:maturity:      new
:depends:       qubes
:platform:      all

Implementation of Qubes qvm utilities
=====================================

Salt can manage many Qubes settings via the qvm state module.

Management declarations are typically rather simple:

.. code-block:: yaml

    appvm:
      qvm.prefs
        - label: green
'''

# Import python libs
import logging
#import os
#import re

# Import salt libs
import salt.utils
from salt.output import nested
#from salt.utils import namespaced_function as _namespaced_function
#from salt.utils.odict import OrderedDict as _OrderedDict
#from salt._compat import string_types
from salt.exceptions import (
    CommandExecutionError, MinionError, SaltInvocationError
)

log = logging.getLogger(__name__)


def __virtual__():
    '''
    Only make these states available if a qvm provider has been detected or
    assigned for this minion
    '''
    return 'qvm.get_prefs' in __salt__

'''
TODO:
=====

- Consider creating an additional state that will allow all vm related
  configurations to be within one state (qvm.vm)

- Functions to implement (qvm-commands):
  [ ] Not Implemented
  [X] Implemented
  [1-9] Next to Implement

  [ ] qvm-add-appvm       [X] qvm-create              [ ] qvm-ls                       [2] qvm-shutdown
  [ ] qvm-add-template    [ ] qvm-create-default-dvm  [ ] qvm-pci                      [2] qvm-start
  [ ] qvm-backup          [ ] qvm-firewall            [X] qvm-prefs                    [ ] qvm-sync-appmenus
  [ ] qvm-backup-restore  [ ] qvm-grow-private        [X] qvm-remove                   [ ] qvm-sync-clock
  [ ] qvm-block           [ ] qvm-grow-root           [ ] qvm-revert-template-changes  [ ] qvm-template-commit
  [X] qvm-check           [ ] qvm-init-storage        [3] qvm-run                      [ ] qvm-trim-template
  [X] qvm-clone           [2] qvm-kill                [1] qvm-service                  [ ] qvm-usb
'''


def _nested_output(obj):
    '''
    Serialize obj and format for output
    '''
    nested.__opts__ = __opts__
    ret = nested.output(obj).rstrip()
    return ret


# XXX: rename to something more descriptive; used to get error code and output only
def _default(name, function, *args, **kwargs):
    ret = {'name': name,
           'stdout': '',
           'stderr': '',
           'retcode': 0,
           'changes': {},
          }

    result = __salt__[function](name, *args, **kwargs)
    ret.update(result)

    ret['comment'] = ret['stdout']
    ret['result'] = True if not ret['retcode'] else False
    return ret


def check(name, **kwargs):
    '''
    Returns True is vmname exists
    '''
    ret = _default(name, 'qvm.check')
    return ret


def missing(name, **kwargs):
    '''
    Returns True is vmname does not exist
    '''
    ret = _default(name, 'qvm.check')
    ret['result'] = not ret['result']
    return ret


def running(name, **kwargs):
    '''
    Returns True is vmname is running, False if not
    '''
    ret = _default(name, 'qvm.state')
    return ret


def dead(name, **kwargs):
    '''
    Returns True is vmname is halted
    '''
    ret = _default(name, 'qvm.state')
    ret['result'] = not ret['result']
    return ret


def create(name, **kwargs):
    '''
    '''
    ret = {'name': name,
           'changes': {},
           'result': False,
           'comment': ''}

    args, fnargs = salt.utils.arg_lookup(__salt__['qvm.create']).values()
    for key, value in kwargs.items():
        if key in fnargs:
            fnargs[key] = value

    # Support test mode only
    if __opts__['test'] == True:
        # Pre-check if create should succeed
        ret = _default(name, 'qvm.check')
        ret['result'] = not ret['result']
        if not ret['result']:
            return ret
        ret['result'] = None
        ret['comment'] = 'VM {0} will be created\n{1}'.format(name, _nested_output(fnargs))
        return ret

    ret = _default(name, 'qvm.create', **fnargs)
    return ret


def remove(name, **kwargs):
    '''
    '''
    ret = {'name': name,
           'changes': {},
           'result': False,
           'comment': ''}

    args, fnargs = salt.utils.arg_lookup(__salt__['qvm.remove']).values()
    for key, value in kwargs.items():
        if key in fnargs:
            fnargs[key] = value

    # Support test mode only
    if __opts__['test'] == True:
        # Pre-check if create should succeed
        ret = _default(name, 'qvm.check')
        if not ret['result']:
            return ret
        ret['result'] = None
        ret['comment'] = 'VM {0} will be removed\n{1}'.format(name, _nested_output(fnargs))
        return ret

    ret = _default(name, 'qvm.remove', **fnargs)
    return ret


def clone(name, target, **kwargs):
    '''
    '''
    ret = {'name': name,
           'changes': {},
           'result': False,
           'comment': ''}

    args, fnargs = salt.utils.arg_lookup(__salt__['qvm.clone']).values()
    for key, value in kwargs.items():
        if key in fnargs:
            fnargs[key] = value

    # Support test mode only
    if __opts__['test'] == True:
        # Pre-check if create should succeed
        ret = _default(name, 'qvm.check')
        ret['result'] = not ret['result']
        if not ret['result']:
            return ret
        ret['result'] = None
        ret['comment'] = 'VM {0} will be cloned\n{1}'.format(name, _nested_output(fnargs))
        return ret

    fnargs['target'] = target
    ret = _default(name, 'qvm.clone', **fnargs)
    return ret


def service(name, **kwargs):
    ret = {'name': name,
           'changes': {},
           'result': False,
           'comment': ''}
    # Support test mode only
    if new_state and __opts__['test'] == True:
            ret['result'] = None
            ret['comment'] = 'Preferences of {0} will be changed'.format(name)
            return ret
    ret['result'] = True
    ret['comment'] = 'Preferences are already in desired state for {0}'.format(name)
    return ret


def prefs(name, **kwargs):
    '''
    Sets vmname preferences (qvm-prefs)
    '''
    ret = {'name': name,
           'changes': {},
           'result': False,
           'comment': ''}

    # Support test mode only
    if __opts__['test'] == True:
        current_state = __salt__['qvm.prefs'](name)
        data = dict([(key, value) for key, value in kwargs.items() if value != current_state[key]])
        ret['result'] = None
        ret['comment'] = 'The following preferences will be changed:\n{0}'.format(_nested_output(data))
        return ret

    ret = _default(name, 'qvm.prefs', **kwargs)
    return ret
