/* inspired by https://github.com/utPLSQL/utPLSQL/blob/develop/source/create_utplsql_owner.sql */

whenever sqlerror exit failure rollback
whenever oserror exit failure rollback

set echo off
set feedback off
set heading off
set verify off

define nettle_user       = &1
define nettle_password   = &2
define nettle_tablespace = &3

prompt Creating Nettle.pl user &&nettle_user

create user &nettle_user identified by &nettle_password default tablespace &nettle_tablespace quota unlimited on &nettle_tablespace;

grant create session, create sequence, create procedure, create type, create table, create view, create synonym to &nettle_user;

grant execute on dbms_lock to &nettle_user;

grant execute on dbms_crypto to &nettle_user;

grant alter session to &nettle_user;

