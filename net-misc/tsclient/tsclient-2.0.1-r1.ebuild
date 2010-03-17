# Copyright 1999-2009 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/net-misc/tsclient/tsclient-2.0.1.ebuild,v 1.2 2009/11/09 19:23:39 fauli Exp $

EAPI=2

inherit eutils autotools gnome2

DESCRIPTION="GTK2 frontend for rdesktop"
HOMEPAGE="http://sourceforge.net/projects/tsclient"
SRC_URI="mirror://sourceforge/${PN}/${P}.tar.bz2"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE="networkmanager"

# Too broken upstream to support
RESTRICT=test

RDEPEND="x11-libs/gtk+:2
	dev-libs/glib:2
	gnome-base/libglade:2.0
	gnome-base/libgnome
	gnome-base/libgnomeui
	gnome-base/gnome-desktop
	networkmanager? ( net-misc/networkmanager )"

DEPEND="${RDEPEND}
	gnome-base/gconf
	>=dev-util/intltool-0.27
	dev-util/pkgconfig"

RDEPEND="${RDEPEND}
	>=net-misc/rdesktop-1.3.0"

src_prepare() {
	if use networkmanager ; then
		sed -i -e 's:libnm_glib:libnm-glib:' "${S}"/configure.ac || die
	else
		epatch "${FILESDIR}"/${P}-no-networkmanager.patch
	fi

	# For recent libgnomeui
	sed -i -e 's:libgnome-2\.0:\0 libgnomeui-2\.0:' \
		configure.ac || die

	# don't seem to be actually needed
#	sed -i -e 's:libnotify gconf-2.0::' \
#		configure.ac || die

	eautoreconf
	default
}

src_configure() {
	econf \
		--disable-static \
		--disable-dependency-tracking
}

src_compile() {
	emake -j1 || die "emake failed"
}

src_install() {
	emake DESTDIR="${D}" install || die "install failed"
	dodoc AUTHORS NEWS README TODO || die

#	find "${D}" -name '*.la' -delete || die

	# Don't install headers since we don't have any plugin that uses
	# tsclient. If upstream ever release further plugins we'll restore
	# them, but for now it seems like they just use a single plugin
	# for the sake of it.
#	rm -r "${D}"/usr/include || die
}
