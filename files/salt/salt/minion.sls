##
# Install salt-minion and its configuration files
#
##

include:
  - salt

salt-minion:
  pip.installed:
    - name: salt
  service.running:
    - name: salt-minion
    - enable: True
    - require:
      - pip: salt
    - watch:
      - file: /etc/salt/minion
      - file: /etc/init.d/salt-minion

# salt-minion init file
#/etc/init.d/salt-minion:
#  file.managed:
#    - source: salt://salt/files/minion.init
#    - user: root
#    - group: root
#    - mode: 755

# salt-minion configuration file
/etc/salt/minion:
  file.managed:
    - source: salt://salt/files/minion
    - user: root
    - group: root
    - mode: 644
