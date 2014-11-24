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
      - file: /etc/systemd/system/salt-minion.service

# salt-minion unit file
/etc/systemd/system/salt-minion.service:
  file.managed:
    - source: salt://salt/files/salt-minion.service
    - user: root
    - group: root
    - mode: 755

# salt-minion configuration file
/etc/salt/minion:
  file.managed:
    - source: salt://salt/files/minion
    - user: root
    - group: root
    - mode: 644
