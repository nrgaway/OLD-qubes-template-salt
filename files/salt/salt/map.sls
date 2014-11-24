#!pyobjects

class SaltMap(Map):
    # Generic package names

    class Debian:
        python_dev = 'python-dev'
        python_m2crypto = 'python-m2crypto'
        libevent_dev = 'libevent-dev'

    class Ubuntu:
        __grain__ = 'os'
        python_dev = 'python-dev'
        python_m2crypto = 'python-m2crypto'
        libevent_dev = 'libevent-dev'

    class RedHat:
        python_dev = 'python-devel'
        python_m2crypto = 'm2crypto'
        libevent_dev = 'libevent-devel'
