##
# salt-halite
# -----------
# (Code-name) Halite is a Salt GUI. Status is pre-alpha. 
# Contributions are very welcome. Join us in #salt on Freenode or on the salt-users mailing list.
#
# TODO:  Start it; not sure how to do it yet without using cmd
##

include:
  - salt.master

salt-halite-dependencies:
  pkg.installed:
    - names:
      - gcc
      - python-dev
      - libevent-dev

salt-halite-pip-dependencies:
  pip.installed:
    - names:
      - CherryPy 
      - gevent
    - require:
      - pip: salt-master
      - pkg: salt-halite-dependencies

# Install development version from git
salt-halite:
  pip.installed:
    - name: salt-halite 
    - editable: "git+https://github.com/saltstack/halite.git#egg=halite"
    #- no_deps: True # We satisfy deps already 
    - upgrade: True
    - require:
      - pip: salt-master
      - pip: salt-halite-pip-dependencies
      - pkg: git
  #service.running:
  #  - name: salt-halite
  #  #- name: halite
  #  - enable: False
  #  - require:
  #    - pip: salt-master
  #  - watch:
  #    - file: /etc/salt/master.d/halite.conf

# halite configuration file
/etc/salt/master.d/halite.conf:
  file.managed:
    - source: salt://salt/files/master.d/halite.conf
    - user: root
    - group: root
    - mode: 640
    - watch_in:
      - service: salt-master

