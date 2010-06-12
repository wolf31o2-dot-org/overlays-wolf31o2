# Copyright 1999-2008 Gentoo Foundation ; 2008-2010 Chris Gianelloni
# Distributed under the terms of the GNU General Public License v2
# $Id$

EAPI=2

inherit eutils webapp depend.php

# Support for _p* in version
MY_P=${P/_p*/}
MY_PV=${PV/_p*/}
MY_P=${P/_/-}
MY_PV=${PV/_/-}

# This is the Plugin Architecture version
PIA_V=2.8

# Are there any official patches?
UPSTREAM_HAS_PATCHES=0

CACTI_BASE_URI="http://www.cacti.net/downloads"
CACTI_PLUG_URI="http://mirror.cactiusers.org/downloadsi/plugins"

# Download from beta location if beta is in ${PV}
if [ "${PV/_beta/}" != "${PV}" ] ; then
	CACTI_BASE_URI="${CACTI_BASE_URI}/beta"
	CACTI_PLUG_URI="${CACTI_BASE_URI}"
fi

DESCRIPTION="a complete frontend to rrdtool"
HOMEPAGE="http://www.cacti.net/"
SRC_URI="${CACTI_BASE_URI}/${MY_P}.tar.gz
	pluginarch? (
		${CACTI_PLUG_URI}/${PN}-plugin-${MY_PV}-PA-v${PIA_V}.tar.gz )"

# patches
if [ "${UPSTREAM_HAS_PATCHES}" == "1" ] ; then
	UPSTREAM_PATCHES="cli_add_graph
		snmp_invalid_response
		template_duplication
		fix_icmp_on_windows_iis_servers
		cross_site_fix
		sql_injection_template_export"
	for i in ${UPSTREAM_PATCHES} ; do
		SRC_URI="${SRC_URI} ${CACTI_BASE_URI}/patches/${PV/_p*}/${i}.patch"
	done
fi

SRC_URI="${SRC_URI}
	http://docs.cacti.net/_media/plugin:autom8-v0.33.tgz -> autom8-0.33.tar.gz"

LICENSE="GPL-2"
#KEYWORDS="~amd64 ~x86"
KEYWORDS=""
RESTRICT="primaryuri"
IUSE="doc ldap +pluginarch +snmp"

DEPEND="app-arch/unzip"

need_php_cli
need_httpd_cgi
need_php_httpd

RDEPEND="dev-php/adodb
	net-analyzer/rrdtool
	snmp? ( net-analyzer/net-snmp )
	ldap? ( net-nds/openldap )
	virtual/mysql
	virtual/cron"

# Most code shamelessly stolen from dobin and newbin
docrond() {
	source "${PORTAGE_BIN_PATH:-/usr/lib/portage/bin}"/isolated-functions.sh

	if [[ $# -lt 1 ]] ; then
		vecho "$0: at least one argument needed" 1>&2
		exit 1
	fi

	if [[ ! -d ${D}/etc/cron.d ]] ; then
		install -d "${D}/etc/cron.d" || exit 2
	fi

	ret=0

	for x in "$@" ; do
		if [[ -e ${x} ]] ; then
			install -m0644 -o ${PORTAGE_INST_UID:-0} -g ${PORTAGE_INST_GID:-0} \
			"${x}" "${D}/etc/cron.d"
		else
			echo "!!! ${0##*/}: $x does not exist" 1>&2
			false
		fi
		((ret+=$?))
	done

	return ${ret}
}

newcrond() {
	if [[ -z ${T} ]] || [[ -z ${2} ]] ; then
		echo "$0: Need two arguments, old file and new file" 1>&2
		exit 1
	fi

	if [ ! -e "$1" ] ; then
		echo "!!! ${0##*/}: $1 does not exist" 1>&2
		exit 1
	fi

	rm -rf "${T}/${2}" && \
	cp -f "${1}" "${T}/${2}" && \
	docrond "${T}/${2}"
}

src_unpack() {
	# The first thing we do is unpack our sources
	unpack ${MY_P}.tar.gz
	if use pluginarch; then
		unpack cacti-plugin-${MY_PV}-PA-v${PIA_V}.zip
		unpack autom8-0.33.tar.gz
	fi
}

src_prepare() {
	# Add any official patches from upstream
	if [ "${UPSTREAM_HAS_PATCHES}" == "1" ] ; then
		[ ! ${MY_P} == ${P} ] && mv ${MY_P} ${P}
		# patches
		for i in ${UPSTREAM_PATCHES} ; do
			EPATCH_OPTS="-p1 -d ${S} -N" epatch "${DISTDIR}"/${i}.patch
		done ;
	fi

	EPATCH_OPTS="-p1 -d ${S} -N" epatch "${FILESDIR}"/${P}-rrdtool14.patch

	# Add the Plugin Architecture
	if use pluginarch; then
		cd "${S}"
		EPATCH_OPTS="-p1 -N -d ${S} -F4" \
			epatch "${WORKDIR}"/cacti-plugin-arch/cacti-plugin-${MY_PV}-PA-v${PIA_V}.diff
		cp -f "${WORKDIR}"/cacti-plugin-arch/pa.sql "${S}"
		# Fix the patch, since this deletes lines, we have to add in some code
		# to keep this from happening on version bumps.
		case ${PIA_V} in
			2.5) sed -i -e '197,+2d' "${S}"/include/global.php ;;
			2.6) sed -i -e '198,+2d' "${S}"/include/global.php ;;
		esac

		AUTOM8_PATCHES="cli
			lib_api_automation_tools.php
			lib_api_tree.php
			host.php
			lib_api_device.php
			lib_data_query.php"
		einfo "Adding autom8 patches"
		for p in ${AUTOM8_PATCHES} ; do
			epatch "${WORKDIR}"/autom8/patches-087e/${p}.patch
		done
		# Patch from nectar plugin
		epatch "${FILESDIR}"/${P}-nectar-0.26-lib-html_utility.patch
		# Patches from TheWitness in Cacti upstream SVN
		epatch \
			"${FILESDIR}"/${P}-lossless-reindexing.patch \
			"${FILESDIR}"/${P}-multithreaded-host.patch \
			"${FILESDIR}"/${P}-undefined-multi-output.patch
		# Patch from Howie from Cacti forums:
		# http://forums.cacti.net/about33620.html
		epatch "${FILESDIR}"/${P}-logintitle.patch
	fi

	rm -rf lib/adodb
	# Use sed-fu to use the system adodb, rather than the bundled one
	sed -i -e \
		's:$config\["library_path"\] . "/adodb/adodb.inc.php":"adodb/adodb.inc.php":' \
		"${S}"/include/global.php || die "failed sed for adodb"

	__phpfiles=`find -type f -name '*.php'`

	edos2unix ${__phpfiles}

	sed -i -e \
		's:mysql_error:adodb_error:' \
		${__phpfiles} || die "failed sed for mysql_error"
}

pkg_setup() {
	### TODO:
	### - check for USE=sharedext for PHP and act accordingly
	### - check for SSL/SASL and act accordingly (including LDAP!)

	local __extra_php_flags=
	local __default_php_flags="cli mysql xml session pcre sockets"
	webapp_pkg_setup
	has_php

	# Check if SNMP support is requested
	if use snmp; then
		__extra_php_flags="snmp"
		einfo "Enabling built-in SNMP support"
	else
		ewarn "Disabling built-in SNMP support (not recommended)"
	fi

	# Check if LDAP authentication is requested
	if use ldap; then
		__extra_php_flags="$__extra_php_flags ldap"
		einfo "Enabling built-in LDAP authentication support"
	else
		ewarn "Disabling built-in LDAP authentication support"
		einfo "You can still use LDAP authentication via Web Basic"
		einfo "authentication on your web server."
	fi

	# Now, check if our PHP has everything that it needs
	require_php_with_use $__default_php_flags $__extra_php_flags
}

src_install() {
	webapp_src_preinst
	dodir ${MY_HTDOCSDIR}

	rm -f LICENSE README
	dodoc docs/{CHANGELOG,CONTRIB,README,txt/manual.txt}
#	if use doc ; then
#		einfo "Installing HTML Cacti manual into ${MY_HTDOCSDIR}/manual"
#		docinto ${MY_HTDOCSDIR}/manual
#		dohtml -r docs/html/*
#	fi

	mv docs/html manual
	rm -rf docs

	newcrond "${FILESDIR}"/cacti-poller.crond cacti-poller
	newconfd "${FILESDIR}"/cacti.confd cacti
	cp -f \
		"${FILESDIR}"/${P}-lossless-reindexing.sql \
		"${FILESDIR}"/${P}-multithreaded-host.sql \
		"${D}"${MY_HTDOCSDIR}
	cp -r . "${D}"${MY_HTDOCSDIR}

	webapp_serverowned -R ${MY_HTDOCSDIR}/rra
	webapp_serverowned -R ${MY_HTDOCSDIR}/log
	webapp_postinst_txt en "${FILESDIR}"/postinstall-en.txt

	if use vhosts ; then
		webapp_configfile ${MY_HTDOCSDIR}/include/config.php
	else
		dodir /etc/cacti
		mv "${D}"${MY_HTDOCSDIR}/include/config.php "${D}"/etc/cacti
		dosym /etc/cacti/config.php ${MY_HTDOCSDIR}/include/config.php
	fi

	webapp_src_install
}
