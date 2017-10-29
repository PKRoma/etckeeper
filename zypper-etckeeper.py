#!/usr/bin/python

import errno
import subprocess
import zypp_plugin
import os

def _call_etckeeper(install_arg):
    # zypper interprets the plugin's stdout as described in
    # http://doc.opensuse.org/projects/libzypp/HEAD/zypp-plugins.html so it's
    # important that we don't write anything to it. We therefore redirect
    # etckeeper's stdout to the plugin's stderr. Since zypper writes the
    # stderr of plugins to its log file, etckeeper's stdout will go there as
    # well.

    subprocess.call(['etckeeper', install_arg], stdout=2)


class EtckeeperPlugin(zypp_plugin.Plugin):
    def PLUGINBEGIN(self, headers, body):
        _call_etckeeper('pre-install')
        self.ack()

    def PLUGINEND(self, headers, body):
        try:
            _call_etckeeper('post-install')
        except OSError as e:
            # if etckeeper was just removed, executing it will fail with
            # ENOENT
            if e.errno != errno.ENOENT:
                # reraise so that we don't hide other errors than etckeeper
                # not existing
                raise
        self.ack()


os.environ["LANG"] = "C"
plugin = EtckeeperPlugin()
plugin.main()
