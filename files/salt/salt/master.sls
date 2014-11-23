##
# Install salt-master and its configuration files
#
# TODO:
#   - generate keys automatically (ONLY ON NEW INSTALLS)
#   - auto accept minions keys somehow
#   - maybe keys should be pillars so all minions won't see them
#
##

include:
  - salt

salt-master:
  pip.installed:
    - name: salt
  service.running:
    - name: salt-master
    - enable: True
    - require:
      - pip: salt
    - watch:
      - file: /etc/salt/master
      - file: /etc/salt/master.d/nodegroups.conf
      - file: /etc/salt/master
      - file: /etc/init.d/salt-master
      - file: /etc/pki/tls/certs/localhost.crt
      - file: /etc/pki/tls/certs/localhost.key
      - file: /etc/pki/tls/certs/localhost.pem

# salt-master init file
#/etc/init.d/salt-master:
#  file.managed:
#    - source: salt://salt/files/master.init
#    - user: root
#    - group: root
#    - mode: 755

# salt-master configuration file
/etc/salt/master:
  file.managed:
    - source: salt://salt/files/master
    - user: root
    - group: root
    - mode: 640

# nodegroups configuration file
/etc/salt/master.d/nodegroups.conf:
  file.managed:
    - source: salt://salt/files/master.d/nodegroups.conf
    - user: root
    - group: root
    - mode: 640

# Localhost tls certificate 
/etc/pki/tls/certs/localhost.crt:
  file.managed:
    - source: salt://salt/files/pki/localhost.crt
    - user: root
    - group: root
    - mode: 600

# Localhost tls key
/etc/pki/tls/certs/localhost.key:
  file.managed:
    - source: salt://salt/files/pki/localhost.key
    - user: root
    - group: root
    - mode: 600

# Localhost tls certificate and key
/etc/pki/tls/certs/localhost.pem:
  file.managed:
    - source: salt://salt/files/pki/localhost.pem
    - user: root
    - group: root
    - mode: 600
