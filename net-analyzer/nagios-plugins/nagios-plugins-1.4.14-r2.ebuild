# Copyright 1999-2009 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/net-analyzer/nagios-plugins/nagios-plugins-1.4.13-r3.ebuild,v 1.1 2009/05/15 17:32:37 dertobi123 Exp $

EAPI=2

inherit eutils autotools

DESCRIPTION="plugins to make Nagios work properly"
HOMEPAGE="http://www.nagios.org/"
SRC_URI="mirror://sourceforge/nagiosplug/${P}.tar.gz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="amd64 x86"
IUSE="+ssl samba mysql postgres ldap snmp nagios-dns nagios-ntp nagios-ping
nagios-ssh nagios-game ups ipv6 radius +suid jabber"
#nls gnutls

# This map is pretty much taken from REQUIREMENTS
#
# check_ldaps, check_http, check_tcp, check_smtp: openssl/gnutls
# check_fping: fping
# check_game: qstat
# check_hpjd: net-snmp
# check_ldap: openldap
# check_mysql, check_mysql_query: mysql
# check_pqsql: postgresql-libs
# check_radius: radiusclient-ng/radiusclient
# check_snmp: net-snmp
# check_ifstatus, check_ifoperstatus: Net-SNMP
# check_nwstat: mrtgext nlm for novell
# check_nt: nsclient++ on remote
# check_ups: nut
# check_ide_smart: smartlinux
# Class-Accessor-0.31.tar.gz Config-Tiny-2.10.tar.gz Math-Calc-Units-1.06.tar.gz
# Nagios-Plugin-0.27.tar.gz Params-Validate-0.88.tar.gz Test-Simple-0.70.tar.gz
# bowen-langley_plugins.tar.gz check_radius.tar.gz fetchlog-0.94.tar.gz
# check_bgp-1.0.tar.gz check_traffic-0.91b.tar.gz


DEPEND="ldap? ( >=net-nds/openldap-2.0.25 )
	mysql? ( virtual/mysql )
	postgres? ( >=virtual/postgresql-base-7.2 )
	ssl? ( >=dev-libs/openssl-0.9.6g )
	radius? ( >=net-dialup/radiusclient-0.3.2 )"

RESTRICT="test"

RDEPEND="${DEPEND}
	>=dev-lang/perl-5.6.1-r7
	samba? ( >=net-fs/samba-2.2.5-r1 )
	snmp? ( >=dev-perl/Net-SNMP-4.0.1-r1
			>=net-analyzer/net-snmp-5.0.6
			)
	mysql? ( dev-perl/DBI
			 dev-perl/DBD-mysql )
	nagios-dns? ( >=net-dns/bind-tools-9.2.2_rc1 )
	nagios-ntp? ( >=net-misc/ntp-4.1.1a )
	nagios-ping? ( >=net-analyzer/fping-2.4_beta2-r1 )
	nagios-ssh? ( >=net-misc/openssh-3.5_p1 )
	ups? ( >=sys-power/nut-1.4 )
	!sparc? ( nagios-game? ( >=games-util/qstat-2.6 ) )
	jabber? ( >=dev-perl/Net-Jabber-2.0 )"

pkg_setup() {
	enewgroup nagios
	enewuser nagios -1 /bin/bash /var/nagios/home nagios
}

src_unpack() {
	unpack ${A}
	cd "${S}"

	if ! use radius; then
		EPATCH_OPTS="-p1 -d ${S}" epatch \
		"${FILESDIR}"/nagios-plugins-1.4.10-noradius.patch
	fi

	epatch "${FILESDIR}"/${PN}-1.4.10-contrib.patch
	epatch "${FILESDIR}"/${PN}-1.4.12-pgsqlconfigure.patch

	eautoreconf
}

src_compile() {

	local conf="--disable-dependency-tracking --enable-extra-opts --without-world-permissions"
	if use ssl; then
		conf="${conf} --with-openssl=/usr"
	else
		conf="${conf} --without-openssl"
	fi

	if use postgres; then
		conf="${conf} --with-pgsql=/usr"
	fi

	econf \
		$(use_with mysql) \
		$(use_with ipv6) \
		${conf} \
		--host=${CHOST} \
		--prefix=/usr \
		--libexecdir=/usr/$(get_libdir)/nagios/plugins \
		--sysconfdir=/etc/nagios || die "econf failed"

	# fix problem with additional -
	sed -i -e 's:/bin/ps -axwo:/bin/ps axwo:g' config.h || die "sed failed"

	emake || die "emake failed"
}

src_install() {
	mv "${S}"/contrib/check_compaq_insight.pl "${S}"/contrib/check_compaq_insight.pl.msg
	chmod +x "${S}"/contrib/*.pl

	sed -i -e '1s;#!.*;#!/usr/bin/perl -w;' "${S}"/contrib/*.pl || die "sed failed"
	sed -i -e s#/usr/nagios/libexec#/usr/$(get_libdir)/nagios/plugins#g "${S}"/contrib/*.pl || die "sed failed"
	sed -i -e '30s/use lib utils.pm;/use utils;/' \
		"${S}"/plugins-scripts/check_file_age.pl || die "sed failed"

	dodoc ACKNOWLEDGEMENTS AUTHORS BUGS CODING \
		ChangeLog FAQ NEWS README REQUIREMENTS SUPPORT THANKS

	emake DESTDIR="${D}" install || die "make install failed"

	if use mysql || use postgres; then
		dodir /usr/$(get_libdir)/nagios/plugins
		exeinto /usr/$(get_libdir)/nagios/plugins
		doexe "${S}"/contrib/check_nagios_db.pl
	fi

	if ! use snmp; then
		rm "${D}"/usr/$(get_libdir)/nagios/plugins/check_if{operstatus,status} \
			|| die "Failed to remove SNMP check plugins"
	fi

	mv "${S}"/contrib "${D}"/usr/$(get_libdir)/nagios/plugins/contrib

	if ! use jabber ; then
		rm -f "${D}"usr/$(get_libdir)/nagios/plugins/contrib/nagios_sendim.pl \
			|| die "Failed to remove XMPP notification addon"
	fi

	chown -R root:nagios "${D}"/usr/$(get_libdir)/nagios/plugins \
		|| die "Failed chown of ${D}usr/$(get_libdir)/nagios/plugins"

	chmod -R o-rwx "${D}"/usr/$(get_libdir)/nagios/plugins \
		|| die "Failed chmod of ${D}usr/$(get_libdir)/nagios/plugins"

	if use suid ; then

		chmod 04710 "${D}"/usr/$(get_libdir)/nagios/plugins/{check_icmp,check_ide_smart,check_dhcp} \
			|| die "Failed setting the suid bit for various plugins"
	fi

	dosym /usr/$(get_libdir)/nagios/plugins/utils.sh /usr/$(get_libdir)/nagios/plugins/contrib/utils.sh
	dosym /usr/$(get_libdir)/nagios/plugins/utils.pm /usr/$(get_libdir)/nagios/plugins/contrib/utils.pm
}

pkg_postinst() {
	einfo "This ebuild has a number of USE flags which determines what nagios is able to monitor."
	einfo "Depending on what you want to monitor with nagios, some or all of these USE"
	einfo "flags need to be set for nagios to function correctly."
	echo
	einfo "contrib plugins are installed into /usr/$(get_libdir)/nagios/plugins/contrib"
}
