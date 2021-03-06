# Copyright 1999-2009 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/net-analyzer/ndoutils/ndoutils-1.4_beta8.ebuild,v 1.1 2009/07/21 19:23:37 dertobi123 Exp $

inherit eutils

MY_P=${P/_beta/b}

DESCRIPTION="Nagios addon to store Nagios data in a MySQL database"
HOMEPAGE="http://www.nagios.org"
SRC_URI="mirror://sourceforge/nagios/${MY_P}.tar.gz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="amd64 x86"
IUSE=""

DEPEND="dev-perl/DBI
		dev-perl/DBD-mysql
		virtual/mysql"
RDEPEND="${DEPEND}
	>=net-analyzer/nagios-core-3.0"

S="${WORKDIR}/${MY_P}"

pkg_setup() {
	enewgroup nagios
	enewuser nagios -1 /bin/bash /var/nagios/home nagios
}

src_compile() {
	econf \
		--bindir=/usr/sbin \
		--sbindir=/usr/$(get_libdir)/nagios/cgi-bin \
		--libexecdir=/usr/$(get_libdir)/nagios/plugins \
		--sysconfdir=/etc/nagios/ndo \
		--localstatedir=/var/nagios \
		--enable-mysql \
		--disable-pgsql || die "econf failed"

	emake -j1 || die "emake failed"
}

src_install() {
	dodir /usr/bin
	cp "${S}"/src/{file2sock,log2ndo,ndo2db-3x,ndomod-3x.o,sockdebug} "${D}"/usr/bin

	dodir /usr/share/nagios/
	cp -R "${S}"/db "${D}"/usr/share/nagios

	chown -R root:nagios "${D}"/usr/bin || die "Failed chown of "${D}"/usr/nagios"
	chmod 750 "${D}"/usr/bin/{file2sock,log2ndo,ndo2db-3x,ndomod-3x.o,sockdebug} || die "Failed chmod"

	dodoc README REQUIREMENTS TODO UPGRADING Changelog "docs/NDOUTILS DB Model.pdf" "docs/NDOUtils Documentation.pdf"

	sed -i \
		-e 's:/usr/local/nagios/var/:/var/nagios/:g' \
		"${S}"/config/ndo2db.cfg \
		"${S}"/config/ndomod.cfg

	insinto /etc/nagios/ndo
	doins "${S}"/config/ndo2db.cfg
	doins "${S}"/config/ndomod.cfg

	newinitd "${FILESDIR}"/ndo2db-nagios3.rc ndo2db
}

pkg_postinst() {
	elog "To include NDO in your Nagios setup you'll need to activate the NDO broker module"
	elog "in ${ROOT}etc/nagios/nagios.cfg:"
	elog "\tbroker_module=${ROOT}usr/bin/ndomod-3x.o config_file=${ROOT}etc/nagios/ndo/ndomod.cfg"
}
