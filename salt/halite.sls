#!yamlscript

##
# salt-halite
# -----------
# (Code-name) Halite is a Salt GUI. Status is pre-alpha. 
# Contributions are very welcome. Join us in #salt on Freenode or on the salt-users mailing list.
#
# TODO:  Start it; not sure how to do it yet without using cmd
##

include: salt.certificates

$defaults: False
$pillars:
  auto: False

$python: |
    from salt://salt/map.sls import SaltMap

salt-halite-dependencies:
  pkg.installed:
    - names:
      - gcc
      - $SaltMap.python_dev
      - $SaltMap.libevent_dev

salt-halite-pip-dependencies:
  pip.installed:
    - names:
      - CherryPy 
      - gevent
      - wheel
    - require:
      - pip: salt-master
      - pkg: salt-halite-dependencies

# Install development version from git
salt-halite:
  pip.installed:
    - name: "git+https://github.com/saltstack/halite.git#egg=halite"
    - no_deps: True # We satisfy deps already 
    - use_wheel: true
    - upgrade: True
    - require:
      - pip: salt-master
      - pip: salt-halite-pip-dependencies
      - pkg: git

# halite configuration file
/etc/salt/master.d/halite.conf:
  file.managed:
    - source: salt://salt/files/master.d/halite.conf
    - user: root
    - group: root
    - mode: 640
    - watch_in:
      - service: salt-master
