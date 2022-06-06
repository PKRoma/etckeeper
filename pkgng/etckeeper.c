/*
 * Copyright (c) 2015 William Johansson <radar@radhuset.org>
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer
 *    in this position and unchanged.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY THE AUTHOR(S) ``AS IS'' AND ANY EXPRESS OR
 * IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
 * OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
 * IN NO EVENT SHALL THE AUTHOR(S) BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
 * NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 * THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
 * THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * Based upon the pkg plugin zfssnap:
 * Copyright (c) 2012 Marin Atanasov Nikolov <dnaeon@gmail.com>
 */

#include <stdio.h>
#include <sys/wait.h>
#include <err.h>
#include <errno.h>
#include <spawn.h>

#include <pkg.h>
#define PLUGIN_NAME "etckeeper"
/* TODO: make configuration param? */
#define ETCKEEPER_PATH "/usr/local/bin/etckeeper"

extern char **environ;

struct pkg_plugin *self;

static int pre_install_hook(void *data, struct pkgdb *db);
static int post_install_hook(void *data, struct pkgdb *db);

int
pkg_plugin_init(struct pkg_plugin *p)
{
	self = p;

	pkg_plugin_set(p, PKG_PLUGIN_NAME, PLUGIN_NAME);
	pkg_plugin_set(p, PKG_PLUGIN_DESC, "etckeeper plugin");
	pkg_plugin_set(p, PKG_PLUGIN_VERSION, "1.0.0");

	/* NOTE: upgrade/deinstall is regarded as install */

	if (pkg_plugin_hook_register(p, PKG_PLUGIN_HOOK_PRE_INSTALL, &pre_install_hook) != EPKG_OK) {
		pkg_plugin_error(self, "failed to hook into the library");
		return (EPKG_FATAL);
	}

	if (pkg_plugin_hook_register(p, PKG_PLUGIN_HOOK_POST_INSTALL, &post_install_hook) != EPKG_OK) {
		pkg_plugin_error(self, "failed to hook into the library");
		return (EPKG_FATAL);
	}

	if (pkg_plugin_hook_register(p, PKG_PLUGIN_HOOK_PRE_DEINSTALL, &pre_install_hook) != EPKG_OK) {
		pkg_plugin_error(self, "failed to hook into the library");
		return (EPKG_FATAL);
	}

	if (pkg_plugin_hook_register(p, PKG_PLUGIN_HOOK_POST_DEINSTALL, &post_install_hook) != EPKG_OK) {
		pkg_plugin_error(self, "failed to hook into the library");
		return (EPKG_FATAL);
	}

	if (pkg_plugin_hook_register(p, PKG_PLUGIN_HOOK_PRE_UPGRADE, &pre_install_hook) != EPKG_OK) {
		pkg_plugin_error(self, "failed to hook into the library");
		return (EPKG_FATAL);
	}

	if (pkg_plugin_hook_register(p, PKG_PLUGIN_HOOK_POST_UPGRADE, &post_install_hook) != EPKG_OK) {
		pkg_plugin_error(self, "failed to hook into the library");
		return (EPKG_FATAL);
	}

	return (EPKG_OK);
}

static int
call_etckeeper(char *arg)
{
	int error, pstat;
	pid_t pid;
	char *argv[] = {
		"etckeeper",
		arg,
		NULL,
	};

	if ((error = posix_spawn(&pid, ETCKEEPER_PATH, NULL, NULL,
		__DECONST(char **, argv), environ)) != 0) {
		errno = error;
		pkg_plugin_errno(self, "Failed to spawn process", arg);
		return (EPKG_FATAL);
	}
	while (waitpid(pid, &pstat, 0) == -1) {
		if (errno != EINTR)
			return (EPKG_FATAL);
	}

	if ((error = WEXITSTATUS(pstat)) != 0) {
		pkg_plugin_error(self, "etckeeper failed with exit code %d", error);
		return (EPKG_FATAL);
	}

	return (EPKG_OK);
}

static int
pre_install_hook(void *data, struct pkgdb *db)
{
	return call_etckeeper("pre-install");
}

static int
post_install_hook(void *data, struct pkgdb *db)
{
	return call_etckeeper("post-install");
}
