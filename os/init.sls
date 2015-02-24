#!yamlscript

##
# os - os specific packages
##

$defaults: False
$pillars:
  auto: False

general-utilities:
  pkg.installed:
    - names:
      - telnet

$if grains('os_family') == 'Debian':
  $with os-dependencies:
    pkg.installed:
      - names: 
        - apt-file
#    pip.installed:

/root:
  file:
    - recurse
    - source: salt://os/files/root
    - user: root
    - group: root
    - clean: False  # Do not delete all files in target first
    - replace: True  # Replace existing files (n/a in recurse?)
    - dir_mode: 750
    - file_mode: 640
    - makedirs: True

/home/user:
  file:
    - recurse
    - source: salt://os/files/user
    - user: user
    - group: user
    - clean: False  # Do not delete all files in target first
    - replace: True  # Replace existing files (n/a in recurse?)
    - dir_mode: 755
    - file_mode: 644
    - makedirs: True
