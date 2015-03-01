# vim: set syntax=yaml ts=2 sw=2 sts=2 et :

# Test qubes-dom0-update
git:
  pkg.installed:
    - name: git

# Test prefs
fc21:
  qvm.prefs:
    - label: green
    - template: debian-jessie
    - memory: 200
    - maxmem: 2000
    - include_in_backups: True

# Test new state and module to verify detached signed file
#test-file:
#  gpg.verify:
#    - source: salt://vim/init.sls.asc
#    # homedir: /etc/salt/gpgkeys
#    - require:
#      - pkg: gnupg

# Test new state and module to import gpg key
# (moved to salt/gnupg.sls)
#nrgaway_key:
#  gpg.import_key:
#    - source: salt://dom0/nrgaway-qubes-signing-key.asc
#    # homedir: /etc/salt/gpgkeys

# Test new renderer that automatically verifies signed state files
# (vim/init.sls{.asc} is the test file for this)
