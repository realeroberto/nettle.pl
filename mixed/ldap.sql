--------------------------------------------------------------------------------
--
--  A PL/SQL chrestomathy
-- 
--  Module:    mixed
--  Submodule: ldap
--  Purpose:   PL/SQL access to LDAP or Microsoft Active Directory Services
--  Reference: http://ilmarkerm.blogspot.com/2010/08/authenticate-database-user-against.html
--
--  Copyright (c) 2014-5 Roberto Reale
--  
--  Permission is hereby granted, free of charge, to any person obtaining a
--  copy of this software and associated documentation files (the "Software"),
--  to deal in the Software without restriction, including without limitation
--  the rights to use, copy, modify, merge, publish, distribute, sublicense,
--  and/or sell copies of the Software, and to permit persons to whom the
--  Software is furnished to do so, subject to the following conditions:
--  
--  The above copyright notice and this permission notice shall be included in
--  all copies or substantial portions of the Software.
--  
--  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
--  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
--  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
--  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
--  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
--  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
--  DEALINGS IN THE SOFTWARE.
-- 
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
--
--  Example of Use
--
--------------------------------------------------------------------------------
--
--      SET SERVEROUTPUT ON
--      
--      DECLARE
--          p_attrs                  DBMS_LDAP.string_collection;
--          p_server_name            VARCHAR2(30) := 'ldap.domain';
--          p_domain_name            VARCHAR2(30) := 'domain';
--          p_bind_user              VARCHAR2(30) := 'ldapBindUser';
--          p_bind_user_password     VARCHAR2(30) := 'ldapBindUserPassword';
--          p_user_base              VARCHAR2(30) := 'DC=DOMAIN';
--          p_user_name_attribute    VARCHAR2(30) := 'sAMAccountName';
--          p_username               VARCHAR2(30) := 'username';
--          p_search_result          LDAP_UTILS.t_record_table;
--      
--      BEGIN
--          LDAP_UTILS.SET_SERVER_NAME(p_server_name);
--          LDAP_UTILS.SET_DOMAIN_NAME(p_domain_name);
--          LDAP_UTILS.SET_BIND_USER(p_bind_user);
--          LDAP_UTILS.SET_BIND_USER_PASSWORD(p_bind_user_password);
--          LDAP_UTILS.SET_USER_BASE(p_user_base);
--          
--          p_attrs(1) := 'accountExpires';
--          p_attrs(2) := 'pwdLastSet';
--          p_attrs(3) := 'memberOf';
--      
--          --  search and retrieve
--      
--          p_search_result := LDAP_UTILS.SEARCH_LDAP
--              (
--                  p_subtree    => TRUE,
--                  p_attributes => p_attrs, 
--                  p_filter     => '(&(!(userAccountControl=514))(&('
--                                  ||p_user_name_attribute||'='||p_username||
--                                  ')(objectClass=user)))'
--              );
--          
--          --  print results
--      
--          FOR i IN 1 .. p_search_result.COUNT
--          LOOP
--              DBMS_OUTPUT.PUT_LINE('dn=' || p_search_result(i).dn);
--              FOR j IN 1 .. p_search_result(i).attr.COUNT
--              LOOP
--                  DBMS_OUTPUT.PUT_LINE
--                      (
--                          '+ ' 
--                          || p_search_result(i).attr(j).name
--                          || '='
--                          || p_search_result(i).attr(j).value
--                      );
--              END LOOP;
--          END LOOP;
--      END;
--
--------------------------------------------------------------------------------


CREATE OR REPLACE PACKAGE LDAP_UTILS AS

    -------------------------------
    --  Let's define some types  --
    -------------------------------

    TYPE t_attribute IS RECORD
        (
            name     VARCHAR2(200 CHAR),
            value    VARCHAR2(200 CHAR)
        );

    TYPE t_attribute_table IS TABLE OF t_attribute;
  
    TYPE t_record IS RECORD
        (
            dn      VARCHAR2(200 CHAR),
            attr    t_attribute_table
        );

    TYPE t_record_table IS TABLE OF t_record;

    
    ---------------------------
    --  Getters and Setters  --
    ---------------------------

    --  AD server name
    FUNCTION  GET_SERVER_NAME RETURN VARCHAR2;
    PROCEDURE SET_SERVER_NAME(p_server_name IN VARCHAR2);

    --  AD domain name
    FUNCTION  GET_DOMAIN_NAME RETURN VARCHAR2;
    PROCEDURE SET_DOMAIN_NAME(p_domain_name IN VARCHAR2);

    --  LDAP user account that can read user attributes     
    FUNCTION  GET_BIND_USER RETURN VARCHAR2;
    PROCEDURE SET_BIND_USER(p_bind_user IN VARCHAR2);

    --  LDAP path where the user accounts are located
    FUNCTION  GET_BIND_USER_PASSWORD RETURN VARCHAR2;
    PROCEDURE SET_BIND_USER_PASSWORD(p_bind_user_password IN VARCHAR2);

    --  Login restricted to a specific LDAP group
    FUNCTION  GET_USER_BASE RETURN VARCHAR2;
    PROCEDURE SET_USER_BASE(p_user_base IN VARCHAR2);

    --  Secured LDAP connection
    FUNCTION  GET_USE_LDAPS RETURN BOOLEAN;
    PROCEDURE SET_USE_LDAPS(p_use_ldaps IN BOOLEAN);
    FUNCTION  GET_WALLET_LOCATION RETURN VARCHAR2;
    PROCEDURE SET_WALLET_LOCATION(p_wallet_location IN VARCHAR2);
    FUNCTION  GET_WALLET_PASSWORD RETURN VARCHAR2;
    PROCEDURE SET_WALLET_PASSWORD(p_wallet_password IN VARCHAR2);


    --------------------------
    --  Main SEARCH method  --
    --------------------------

    FUNCTION SEARCH_LDAP
        (
            p_subtree    IN BOOLEAN,
            p_attributes IN DBMS_LDAP.string_collection,
            p_filter     IN VARCHAR2
        ) RETURN t_record_table;
	
END LDAP_UTILS;
/



CREATE OR REPLACE PACKAGE BODY LDAP_UTILS AS

    -----------------------
    --  Global settings  --
    -----------------------
	
    g_server_name           VARCHAR2(256);
    g_domain_name           VARCHAR2(256);

    g_bind_user             VARCHAR2(1000);
    g_bind_user_password    VARCHAR2(256);

    g_user_base             VARCHAR2(256);

    g_use_ldaps             BOOLEAN := FALSE;
    g_wallet_location       VARCHAR2(256);
    g_wallet_password       VARCHAR2(256);


    ---------------------------
    --  Getters and Setters  --
    ---------------------------

    FUNCTION GET_SERVER_NAME RETURN VARCHAR2 AS
    BEGIN
        RETURN g_server_name;
    END GET_SERVER_NAME;

    PROCEDURE SET_SERVER_NAME(p_server_name IN VARCHAR2) AS
    BEGIN
        g_server_name := p_server_name;
    END SET_SERVER_NAME;

    
    FUNCTION GET_DOMAIN_NAME RETURN VARCHAR2 AS
    BEGIN
        RETURN g_domain_name;
    END GET_DOMAIN_NAME;

    PROCEDURE SET_DOMAIN_NAME(p_domain_name IN VARCHAR2) AS
    BEGIN
        g_domain_name := p_domain_name;
    END SET_DOMAIN_NAME;

    
    FUNCTION GET_BIND_USER RETURN VARCHAR2 AS
    BEGIN
        RETURN g_bind_user;
    END GET_BIND_USER;

    PROCEDURE SET_BIND_USER(p_bind_user IN VARCHAR2) AS
    BEGIN
        g_bind_user := p_bind_user;
    END SET_BIND_USER;


    FUNCTION GET_BIND_USER_PASSWORD RETURN VARCHAR2 AS
    BEGIN
        RETURN g_bind_user_password;
    END GET_BIND_USER_PASSWORD;

    PROCEDURE SET_BIND_USER_PASSWORD(p_bind_user_password IN VARCHAR2) AS
    BEGIN
        g_bind_user_password := p_bind_user_password;
    END SET_BIND_USER_PASSWORD;


    FUNCTION GET_USER_BASE RETURN VARCHAR2 AS
    BEGIN
        RETURN g_user_base;
    END GET_USER_BASE;

    PROCEDURE SET_USER_BASE(p_user_base IN VARCHAR2) AS
    BEGIN
        g_user_base := p_user_base;
    END SET_USER_BASE;


    FUNCTION GET_USE_LDAPS RETURN BOOLEAN AS
    BEGIN
        RETURN g_use_ldaps;
    END GET_USE_LDAPS;

    PROCEDURE SET_USE_LDAPS(p_use_ldaps IN BOOLEAN) AS
    BEGIN
        g_use_ldaps := p_use_ldaps;
    END SET_USE_LDAPS;


    FUNCTION GET_WALLET_LOCATION RETURN VARCHAR2 AS
    BEGIN
        RETURN g_wallet_location;
    END GET_WALLET_LOCATION;

    PROCEDURE SET_WALLET_LOCATION(p_wallet_location IN VARCHAR2) AS
    BEGIN
        g_wallet_location := p_wallet_location;
    END SET_WALLET_LOCATION;
    
    
    FUNCTION GET_WALLET_PASSWORD RETURN VARCHAR2 AS
    BEGIN
        RETURN g_wallet_password;
    END GET_WALLET_PASSWORD;

    PROCEDURE SET_WALLET_PASSWORD(p_wallet_password IN VARCHAR2) AS
    BEGIN
        g_wallet_password := p_wallet_password;
    END SET_WALLET_PASSWORD;


    ------------------------------
    --  Private CONNECT helper  --
    ------------------------------
    
    FUNCTION LDAP_CONNECT
        (
            p_username IN VARCHAR2,
            p_password IN VARCHAR2
        ) RETURN DBMS_LDAP.SESSION
    AS
        v_sess  DBMS_LDAP.SESSION;
        i       PLS_INTEGER;
    BEGIN
        DBMS_LDAP.USE_EXCEPTION := TRUE;

        v_sess:= DBMS_LDAP.INIT(g_server_name, CASE WHEN g_use_ldaps THEN 636 ELSE 389 END);

        IF g_use_ldaps
        THEN
            i:= DBMS_LDAP.OPEN_SSL(v_sess, g_wallet_location, g_wallet_password, 2);
        END IF;

        i:= DBMS_LDAP.SIMPLE_BIND_S(v_sess, p_username||'@'||g_domain_name, p_password);

        IF i <> 0
        THEN
            RAISE_APPLICATION_ERROR(-20401, 'Bind to LDAP failed.');
        END IF;

        RETURN v_sess;

    END LDAP_CONNECT;


    --------------------------
    --  Main SEARCH method  --
    --------------------------

    FUNCTION SEARCH_LDAP
        (
            p_subtree    IN BOOLEAN,
            p_attributes IN DBMS_LDAP.string_collection,
            p_filter     IN VARCHAR2
        ) RETURN t_record_table
    AS
        p_result       t_record_table;
        v_sess         DBMS_LDAP.SESSION;
        ignore         PLS_INTEGER;
        retval         PLS_INTEGER;
        l_message      DBMS_LDAP.MESSAGE;
        l_entry        DBMS_LDAP.MESSAGE;
        l_vals         DBMS_LDAP.string_collection;
        l_attr_name    VARCHAR2(256 CHAR);
        l_ber_element  DBMS_LDAP.BER_ELEMENT;
        p_dn           VARCHAR2(200 CHAR);
        p_search_idx   NUMBER:= 0;
        p_attr_idx     NUMBER:= 0;
	BEGIN
        p_result := t_record_table();

        v_sess := LDAP_CONNECT(g_bind_user, g_bind_user_password);

        retval := DBMS_LDAP.SEARCH_S
        (
            ld       => v_sess, 
            base     => g_user_base, 
            scope    => CASE
                            WHEN p_subtree THEN DBMS_LDAP.SCOPE_SUBTREE
                            ELSE DBMS_LDAP.SCOPE_ONELEVEL
                        END,
            filter   => p_filter,
            attrs    => p_attributes,
            attronly => 0,
            res      => l_message
        );
			
        IF DBMS_LDAP.COUNT_ENTRIES(ld => v_sess, msg => l_message) > 0
        THEN
            l_entry := DBMS_LDAP.FIRST_ENTRY(ld  => v_sess, msg => l_message);

            WHILE l_entry IS NOT NULL
            LOOP
                p_result.extend;

                p_search_idx                := p_search_idx + 1;
                p_result(p_search_idx).dn   := DBMS_LDAP.GET_DN(v_sess, l_entry);
                p_result(p_search_idx).attr := t_attribute_table();

                p_attr_idx  := 0;
                l_attr_name := DBMS_LDAP.FIRST_ATTRIBUTE
                (
                    ld        => v_sess,
                    ldapentry => l_entry,
                    ber_elem  => l_ber_element
                );
				
                WHILE l_attr_name IS NOT NULL
                LOOP
                    --  Get all the values for this attribute
                    l_vals := DBMS_LDAP.GET_VALUES
                    (
                        ld        => v_sess,
                        ldapentry => l_entry,
                        attr      => l_attr_name
                    );

                    FOR i IN l_vals.FIRST .. l_vals.LAST
                    LOOP
                        p_result(p_search_idx).attr.extend;
                        p_attr_idx                                    := p_attr_idx + 1;
                        p_result(p_search_idx).attr(p_attr_idx).name  := l_attr_name;
                        p_result(p_search_idx).attr(p_attr_idx).value := l_vals(i);
                    END LOOP values_loop;

                    l_attr_name := DBMS_LDAP.NEXT_ATTRIBUTE
                    (
                        ld        => v_sess,
                        ldapentry => l_entry,
                        ber_elem  => l_ber_element
                    );
                END LOOP;

            l_entry := DBMS_LDAP.NEXT_ENTRY(v_sess, l_entry);
            END LOOP;
        END IF;

        ignore := DBMS_LDAP.UNBIND_S(v_sess);

        RETURN p_result;

    EXCEPTION WHEN OTHERS THEN
        ignore := DBMS_LDAP.UNBIND_S(v_sess);
        RAISE;

    END SEARCH_LDAP;

END LDAP_UTILS;
/

--  ex: ts=4 sw=4 et filetype=sql
