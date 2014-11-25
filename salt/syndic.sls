##
# Install salt-syndic and its configuration files
##

salt-syndic:
  pip.installed:
    - name: salt
  service.running:
    - name: salt-syndic
    - enable: True
    - require:
      - pip: salt
    - watch:
      - file: /etc/systemd/system/salt-syndic.service

# salt-syndic unit file
/etc/systemd/system/salt-syndic.service:
  file.managed:
    - source: salt://salt/files/salt-syndic.service
    - user: root
    - group: root
    - mode: 755
