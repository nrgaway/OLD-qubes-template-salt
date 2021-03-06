#!yamlscript

##
# Install salt base
##

# TODO:
#   - Need to restart salt servers after updating?

$defaults: False
$pillars:
  auto: False

$python: |
    from salt://salt/map.sls import SaltMap
    
salt-dependencies:
  pkg.installed:
    - names:
      - git
      - python
      - $SaltMap.python_dev
      - $SaltMap.python_m2crypto
      - $SaltMap.python_openssl
    - require:
      - pkg: pip-dependencies 
      #- python-jinja2    # APT: 2.7.2-2

salt-pip-dependencies:
  pip.installed:
    - names:
      - pyzmq             # PIP: 14.0.1
      - PyYAML            # PIP: 0.8.4
      - pycrypto          # PIP: 2.6.1
      - msgpack-python    # PIP: 0.3.0
      - jinja2            # 2.7.2
      - psutil            # not-installed 
      - wheel
    - require:
      - pkg: salt-dependencies

# Install from git
salt:
  pip.installed:
    - name: git+https://github.com/saltstack/salt.git@v2014.7.0#egg=salt
    - no_deps: True # We satisfy deps already since we cant build m2crypto on debian/ubuntu
    - install_options: --force-installation-into-system-dir
    - install_options: --prefix=/usr
    - use_wheel: True
    - upgrade: False
    - require:
      - pkg: salt-dependencies
      - pip: salt-pip-dependencies
      - pkg: git

# binddirs script
/usr/lib/salt/bind-directories:
  file.managed:
    - source: salt://salt/files/bind-directories
    - makedirs: True
    - user: root
    - group: root
    - mode: 755
