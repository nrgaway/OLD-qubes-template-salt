#!pyobjects

class ThemeMap(Map):
    class Debian:
       xdg_qubes_settings = '/etc/X11/Xsession.d/25xdg-qubes-settings'

    class Ubuntu:
        __grain__ = 'os'
        xdg_qubes_settings = '/etc/X11/Xsession.d/25xdg-qubes-settings'

    class RedHat:
        xdg_qubes_settings = '/etc/X11/xinit/Xclients.d/25xdg-qubes-settings'
