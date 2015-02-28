git:
  pkg.installed:
    - name: git

# name               : fc21
# label              : orange
# type               : AppVM
# template           : fedora-21-x64
# netvm              : deb-tor
# updateable         : False
# autostart          : False
# installed_by_rpm   : False
# include_in_backups : True
# last_backup        : None
# dir                : /var/lib/qubes/appvms/fc21
# config             : /var/lib/qubes/appvms/fc21/fc21.conf
# pcidevs            : []
# root_img           : /var/lib/qubes/vm-templates/fedora-21-x64/root.img
# root_volatile_img  : /var/lib/qubes/appvms/fc21/volatile.img
# private_img        : /var/lib/qubes/appvms/fc21/private.img
# vcpus              : 8
# memory             : 400
# maxmem             : 4000
# MAC                : 00:16:3E:5E:6C:22 (auto)
# kernel             : 3.12.23-1 (default)
# kernelopts         : nopat (default)
# debug              : off
# default_user       : user
# qrexec_timeout     : 60
# internal           : False

fc21:
  qvm.prefs:
    - label: green
    - template: debian-jessie
    - memory: 200
    - maxmem: 2000
    - include_in_backups: True
