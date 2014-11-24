##
# Disable salt-master
##

salt-master:
  service.dead:
    - name: salt-master
    - enable: False
    - watch:
      - file: /etc/systemd/system/salt-master.service

# salt-master unit file
/etc/systemd/system/salt-master.service:
  file.managed:
    - source: salt://salt/files/salt-master.service
    - user: root
    - group: root
    - mode: 755
