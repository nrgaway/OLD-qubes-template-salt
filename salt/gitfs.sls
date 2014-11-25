##
# Install gitfs file server
##

salt-gitfs:
  pkg.installed:
    - names:
      - python-dulwich
    - require_in:
      - service: salt-master
      - service: salt-minion

# gitfs configuration file
/etc/salt/master.d/gitfs.conf:
  file.managed:
    - source: salt://salt/files/master.d/gitfs.conf
    - user: root
    - group: root
    - mode: 640

# use master gitfs configuration file
/etc/salt/minion.d/gitfs.conf:
  file.managed:
    - source: salt://salt/files/master.d/gitfs.conf
    - user: root
    - group: root
    - mode: 640
