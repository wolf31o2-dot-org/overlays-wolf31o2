# Copyright 1999-2009 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/www-apps/websvn/websvn-2.1.0.ebuild,v 1.3 2009/05/25 18:58:35 ranger Exp $

inherit depend.php eutils webapp

MY_PV="${PV//_/}"

DESCRIPTION="Web-based browsing tool for Subversion (SVN) repositories in PHP"
HOMEPAGE="http://www.websvn.info"
SRC_URI="http://websvn.tigris.org/files/documents/1380/47175/websvn-${MY_PV}.tar.gz"

RESTRICT="mirror"
LICENSE="GPL-2"
IUSE="enscript"
KEYWORDS="~amd64 ~x86"

RDEPEND="dev-util/subversion
	enscript? ( app-text/enscript )"

need_httpd_cgi
need_php_httpd

S="${WORKDIR}"/websvn-${MY_PV}

pkg_setup() {
	webapp_pkg_setup
	has_php
	if [[ ${PHP_VERSION} == "4" ]] ; then
		require_php_with_use expat
	else
		require_php_with_use xml
	fi
}

src_install() {
	webapp_src_preinst

	mv include/{dist,}config.php

	dodoc changes.txt doc/templates.txt
	dohtml doc/*
	rm -rf license.txt changes.txt doc/

	insinto "${MY_HTDOCSDIR}"
	doins -r .

	webapp_configfile "${MY_HTDOCSDIR}"/include/config.php
	webapp_configfile "${MY_HTDOCSDIR}"/wsvn.php

	webapp_serverowned "${MY_HTDOCSDIR}"/cache

	webapp_src_install
}
