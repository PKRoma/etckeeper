# You should configure etckeeper.conf for your distribution before
# installing etckeeper.
CONFFILE=etckeeper.conf
include $(CONFFILE)

DESTDIR?=
prefix=/usr
bindir=${prefix}/bin
etcdir=/etc
mandir=${prefix}/share/man
vardir=/var
systemddir=/lib/systemd/system
completiondir=${prefix}/share/bash-completion/completions
CP=cp -R
INSTALL=install 
INSTALL_EXE=${INSTALL}
INSTALL_DATA=${INSTALL} -m 0644
PYTHON=python
FAKEROOT := $(shell command -v fakeroot 2> /dev/null)
TESTDIR := $(shell mktemp -u -d)

build: etckeeper.spec etckeeper.version
	-$(PYTHON) ./etckeeper-bzr/__init__.py build || echo "** bzr support not built"
	-$(PYTHON) ./etckeeper-dnf/etckeeper.py build || echo "** DNF support not built"

install: etckeeper.version
	mkdir -p $(DESTDIR)$(etcdir)/etckeeper/ $(DESTDIR)$(vardir)/cache/etckeeper/
	$(CP) *.d $(DESTDIR)$(etcdir)/etckeeper/
	$(INSTALL_EXE) daily $(DESTDIR)$(etcdir)/etckeeper/daily
	$(INSTALL_DATA) $(CONFFILE) $(DESTDIR)$(etcdir)/etckeeper/etckeeper.conf
	mkdir -p $(DESTDIR)$(bindir)
	$(INSTALL_EXE) etckeeper $(DESTDIR)$(bindir)/etckeeper
	mkdir -p $(DESTDIR)$(mandir)/man8
	$(INSTALL_DATA) etckeeper.8 $(DESTDIR)$(mandir)/man8/etckeeper.8
	mkdir -p $(DESTDIR)$(completiondir)
	$(INSTALL_DATA) bash_completion $(DESTDIR)$(completiondir)/etckeeper
	mkdir -p $(DESTDIR)$(systemddir)
	$(INSTALL_DATA) systemd/etckeeper.service $(DESTDIR)$(systemddir)/etckeeper.service
	$(INSTALL_DATA) systemd/etckeeper.timer $(DESTDIR)$(systemddir)/etckeeper.timer
ifeq ($(HIGHLEVEL_PACKAGE_MANAGER),apt)
	mkdir -p $(DESTDIR)$(etcdir)/apt/apt.conf.d
	$(INSTALL_DATA) apt.conf $(DESTDIR)$(etcdir)/apt/apt.conf.d/05etckeeper
	mkdir -p $(DESTDIR)$(etcdir)/cruft/filters-unex
	$(INSTALL_DATA) cruft_filter $(DESTDIR)$(etcdir)/cruft/filters-unex/etckeeper
endif
ifeq ($(LOWLEVEL_PACKAGE_MANAGER),pacman)
	mkdir -p $(DESTDIR)$(prefix)/share/libalpm/hooks
	$(INSTALL_DATA) ./pacman-pre-install.hook $(DESTDIR)$(prefix)/share/libalpm/hooks/05-etckeeper-pre-install.hook
	$(INSTALL_DATA) ./pacman-post-install.hook $(DESTDIR)$(prefix)/share/libalpm/hooks/zz-etckeeper-post-install.hook
endif
ifeq ($(LOWLEVEL_PACKAGE_MANAGER),pacman-g2)
	mkdir -p $(DESTDIR)$(etcdir)/pacman-g2/hooks
	$(INSTALL_DATA) pacman-g2.hook $(DESTDIR)$(etcdir)/pacman-g2/hooks/etckeeper
endif
ifeq ($(HIGHLEVEL_PACKAGE_MANAGER),yum)
	mkdir -p $(DESTDIR)$(prefix)/lib/yum-plugins
	$(INSTALL_DATA) yum-etckeeper.py $(DESTDIR)$(prefix)/lib/yum-plugins/etckeeper.py
	mkdir -p $(DESTDIR)$(etcdir)/yum/pluginconf.d
	$(INSTALL_DATA) yum-etckeeper.conf $(DESTDIR)$(etcdir)/yum/pluginconf.d/etckeeper.conf
endif
ifeq ($(HIGHLEVEL_PACKAGE_MANAGER),dnf)
	-$(PYTHON) ./etckeeper-dnf/etckeeper.py install --root=$(DESTDIR) ${PYTHON_INSTALL_OPTS} || echo "** DNF support not installed"
endif
ifeq ($(HIGHLEVEL_PACKAGE_MANAGER),zypper)
	mkdir -p $(DESTDIR)$(prefix)/lib/zypp/plugins/commit
	$(INSTALL) zypper-etckeeper.py $(DESTDIR)$(prefix)/lib/zypp/plugins/commit/zypper-etckeeper.py
endif
	-$(PYTHON) ./etckeeper-bzr/__init__.py install --root=$(DESTDIR) ${PYTHON_INSTALL_OPTS} || echo "** bzr support not installed"
	echo "** installation successful"

clean: etckeeper.spec etckeeper.version
	rm -rf build

test:
	mkdir $(TESTDIR)
ifdef FAKEROOT
	testdir=$(TESTDIR) fakeroot ./test-etckeeper
else
	testdir=$(TESTDIR) ./test-etckeeper
endif
	rm -rf $(TESTDIR)

etckeeper.spec:
	sed -i~ "s/Version:.*/Version: $$(perl -e '$$_=<>;m/\((.*?)(-.*)?\)/;print $$1;'<debian/changelog)/" etckeeper.spec
	rm -f etckeeper.spec~

etckeeper.version:
	sed -i~ "s/Version:.*/Version: $$(perl -e '$$_=<>;m/\((.*?)(-.*)?\)/;print $$1;' <debian/changelog)\"/" etckeeper
	rm -f etckeeper~

.PHONY: etckeeper.spec etckeeper.version
