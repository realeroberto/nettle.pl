#!/bin/sh -e
# vim: set et sw=2 ts=2:

cd utPLSQL/source
$ORACLE_HOME/bin/sqlplus / as sysdba @@install_headless.sql $UTPLSQL_OWNER $UTPLSQL_PASSWORD $UTPLSQL_TABLESPACE
