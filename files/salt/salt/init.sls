##
# Install salt base
#
##

salt-dependencies:
  pkg.installed:
    - names:
      - git
      - python
      - python-dev
      - python-m2crypto
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
    - require:
      - pkg: salt-dependencies

# Install development version from git
salt:
  pip.installed:
    - name: salt 
    #- editable: "git+https://github.com/saltstack/salt.git@develop#egg=salt"
    - editable: "git+https://github.com/saltstack/salt.git@2014.7#egg=salt"
    - no_deps: True # We satisfy deps already since we cant build m2crypto on debian/ubuntu
    #- install_options: "--prefix=/usr --force-installation-into-system-dir"
    - upgrade: True
    - require:
      - pkg: salt-dependencies
      - pip: salt-pip-dependencies
      - pkg: git

