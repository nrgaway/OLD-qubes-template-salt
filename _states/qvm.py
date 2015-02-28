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
#import salt.utils
#from salt.output import nested
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

unset = object()
def prefs(name,
          label=unset,
          type=unset,
          template=unset,
          netvm=unset,
          updateable=unset,
          autostart=unset,
          installed_by_rpm=unset,
          include_in_backups=unset,
          last_backup=unset,
          dir=unset,
          config=unset,
          pcidevs=unset,
          root_img=unset,
          root_volatile_img=unset,
          private_img=unset,
          vcpus=unset,
          memory=unset,
          maxmem=unset,
          MAC=unset,
          kernel=unset,
          kernelopts=unset,
          debug=unset,
          default_user=unset,
          qrexec_timeout=unset,
          internal=unset,
          **kwargs
        ):
    '''
    '''
    kwargs['saltenv'] = __env__

    ret = {'name': name,
           'changes': {},
           'result': False,
           'comment': ''}

    current_state = __salt__['qvm.get_prefs'](name)
    if not current_state:
        ret['result'] = False
        ret['comment'] = 'VM {0} does not exist'.format(name)
        return ret

    new_state = {}
    for key, value in current_state.items():
        arg = locals().get(key, unset)
        if arg != unset and arg != value:
            new_state[key] = arg
            ret['changes'][key] = {}
            ret['changes'][key]['old'] = value
            ret['changes'][key]['new'] = arg

    # Support test mode only
    if new_state and __opts__['test'] == True:
            ret['result'] = None
            ret['comment'] = 'Preferences of {0} will be changed'.format(name)
            return ret

    if new_state:
        result = __salt__['qvm.set_prefs'](name, new_state)
        ret['comment'] = result['comment']

        for key in result['changes'].keys():
            result['changes'][key]['old'] = ret['changes'][key]['old']
        ret['changes'] = result['changes']

        if result['retcode']:
            ret['result'] =  False
            return ret
        ret['result'] = True
        return ret

    ret['result'] = True
    ret['comment'] = 'Preferences are already in desired state for {0}'.format(name)
    return ret
