# Nettle.pl: a PL/SQL chrestomathy

## Usage

Just install the modules you need.

## OS

### Path

Performs manipulation of strings representing filesystem paths.

        select nettle_os_path.dirname('/foo/bar') from dual;
        > /foo

        select nettle_os_path.basename('/foo/bar') from dual;
        > bar

