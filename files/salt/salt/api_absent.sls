##
# Disable salt-api
##

salt-api:
  service.dead:
    - name: salt-api
    - enable: False
    - watch:
      - file: /etc/systemd/system/salt-api.service

# salt-api unit file
/etc/systemd/system/salt-api.service:
  file.managed:
    - source: salt://salt/files/salt-api.service
    - user: root
    - group: root
    - mode: 755
