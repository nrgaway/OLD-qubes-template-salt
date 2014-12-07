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
