#!/bin/bash -e
# vim: set ts=4 sw=4 sts=4 et :

# To activate minion in AppVM run this script in AppVM after it has
# been installed in templateVM
#
# TemplateVM automatically accepts minion when installed

salt-key -y -A
systemctl restart salt-master salt-minion || true
