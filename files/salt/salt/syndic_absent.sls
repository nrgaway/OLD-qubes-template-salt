##
# Disable salt-syndic
##

salt-syndic:
  service.dead:
    - name: salt-syndic
    - enable: False
    - watch:
      - file: /etc/systemd/system/salt-syndic.service

# salt-syndic unit file
/etc/systemd/system/salt-syndic.service:
  file.managed:
    - source: salt://salt/files/salt-syndic.service
    - user: root
    - group: root
    - mode: 755
