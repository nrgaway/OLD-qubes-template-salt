##
# python-pip
#

pip-dependencies:
  pkg.installed:
    - names:
      - python-pip
      - python-dev
      - python-virtualenv
      - build-essential

virtualenvwrapper:
  pip.installed:
    - require:
      - pkg: pip-dependencies
