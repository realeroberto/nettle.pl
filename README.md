# Nettle.pl: a PL/SQL chrestomathy

## Usage

Just install the modules you need.


## TODO

Implement tests by [utPLSQL](https://github.com/utPLSQL/utPLSQL/).


## Network

### Utils

Performs manipulation of IP addresses.

        select nettle_network_utils.ip_in_subnet_as_int('1.2.3.4', '1.2.3.0/16') from dual;
        > 1
        select nettle_network_utils.ip_in_subnet_as_int('1.2.3.4', '1.2.4.0/24') from dual;
        > 0

        select nettle_network_utils.ip_to_int('1.2.3.4') from dual;
        > 16909060

        select nettle_network_utils.int_to_ip(1*256*256*256 + 2*256*256 + 3*256 + 4) from dual;
        > 1.2.3.4


## OS

### Path

Performs manipulation of strings representing filesystem paths.

        select nettle_os_path.dirname('/foo/bar') from dual;
        > /foo

        select nettle_os_path.basename('/foo/bar') from dual;
        > bar

