# Copyright 1999-2009 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/app-mobilephone/obexd/obexd-0.18.ebuild,v 1.2 2009/11/16 15:49:11 nirbheek Exp $

EAPI="2"

DESCRIPTION="OBEX Server and Client"
HOMEPAGE="http://www.bluez.org/"
SRC_URI="mirror://kernel/linux/bluetooth/${P}.tar.gz"
LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE="debug eds"

RDEPEND="eds? ( gnome-extra/evolution-data-server )
	net-wireless/bluez
	>=dev-libs/openobex-1.4
	dev-libs/glib:2
	sys-apps/dbus
	!app-mobilephone/obex-data-server"
DEPEND="${RDEPEND}
	dev-util/pkgconfig"

src_configure() {
	econf \
		$(use_enable debug) \
		$(use_with eds phonebook ebook) \
		--enable-server \
		--enable-client
		# --with-telephony=ebook ?
}

src_install() {
	emake DESTDIR="${D}" install || die "emake install failed"
	dodoc AUTHORS ChangeLog README doc/*.txt
}
