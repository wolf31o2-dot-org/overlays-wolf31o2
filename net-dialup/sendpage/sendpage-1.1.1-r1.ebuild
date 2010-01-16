# Copyright 1999-2008 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Id$

inherit perl-module eutils

MY_P=${PN}-1.001001
DESCRIPTION="Dialup alphapaging software."
HOMEPAGE="http://www.sendpage.org/"
SRC_URI="http://www.sendpage.org/download/${MY_P}.tar.gz"
S="${WORKDIR}/${MY_P}"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64 ~ppc ~x86"
IUSE=""

DEPEND="!net-misc/hylafax
	>=dev-perl/Device-SerialPort-0.13
	>=dev-perl/MailTools-1.44
	>=virtual/perl-libnet-1.11
	>=dev-perl/Net-SNPP-1.13
	dev-perl/DBI"

mydoc="FEATURES THANKS TODO email2page.conf sendpage.cf snpp.conf docs/*"

pkg_setup() {
	enewgroup sms
	enewuser sendpage -1 -1 /var/spool/sendpage sms
}

src_unpack() {
	unpack ${A}
	cd "${S}"
	epatch "${FILESDIR}"/${PV}-makefile.patch
}

src_install() {
	perl-module_src_install
	insinto /etc
	doins sendpage.cf
	newinitd "${FILESDIR}"/sendpage.initd sendpage
	diropts -o sendpage -g sms -m0770
	keepdir /var/spool/sendpage
}
