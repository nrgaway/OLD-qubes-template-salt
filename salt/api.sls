##
# Install salt-api
##

salt-api:
  service.enabled:
    - name: salt-api
    - watch:
      - file: /etc/systemd/system/salt-api.service
    - require:
      - pip: salt-master

# salt-api unit file
/etc/systemd/system/salt-api.service:
  file.managed:
    - source: salt://salt/files/salt-api.service
    - user: root
    - group: root
    - mode: 755
