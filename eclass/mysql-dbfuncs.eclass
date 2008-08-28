# Copyright 2008 Chris Gianelloni
# Distributed under the terms of the GNU General Public License v2
# $Header: $

#
# Original Author: Chris Gianelloni <wolf31o2@wolf31o2.org>
# Purpose: Provide a framework for creating, dropping, and modifying MySQL
# databases via the package manager.

EXPORT_FUNCTIONS pkg_postinst

# Variables to specify in an ebuild which uses this eclass:
# TODO: Add this section
MYSQL_ADMIN=${MYSQL_ADMIN:-root}

mysql-dbfuncs_check_auth() {
	if [ -n "${MYSQL_PASS}" ] ; then
		MYSQL_AUTH="-u${MYSQL_ADMIN} -p${MYSQL_PASS}"
	else
		MYSQL_AUTH="-u${MYSQL_ADMIN}"
	fi
}

# This function creates an empty MySQL database.
mysql-dbfuncs_create_database() {
	[ -z "${MYSQL_DBNAME}" ] && die "You need to specify a database name!"
	mysql-dbfuncs_check_auth
	einfo "Creating a new database ${MYSQL_DBNAME}"
	mysql ${MYSQL_AUTH} ${MYSQL_DBNAME}
}

# This function drops a MySQL database.
mysql-dbfuncs_drop_database() {
	[ -z "${MYSQL_DBNAME}" ] && die "You need to specify a database name!"
	mysql-dbfuncs_check_auth
	einfo "Dropping database ${MYSQL_DBNAME}"
	mysqladmin ${MYSQL_AUTH} drop ${MYSQL_DBNAME}
}

# This function loads a SQL script into the given database.
mysql-dbfuncs_load_sql() {
	if [ -z "${MYSQL_SCRIPTS}" ] || [ -z "${MYSQL_DBNAME}" ] ; then
		die "You need to specify MYSQL_SCRIPTS and MYSQL_DBNAME!"
	else
		mysql-dbfuncs_check_auth
		for sql in ${MYSQL_SCRIPTS} ; do
			einfo "Installing ${sql} into ${MYSQL_DBNAME}"
			mysql ${MYSQL_AUTH} ${MYSQL_DBNAME} < $sql
		done
	fi
}