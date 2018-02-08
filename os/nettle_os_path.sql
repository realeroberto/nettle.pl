--------------------------------------------------------------------------------
--
--  Nettle.pl: a PL/SQL chrestomathy
-- 
--  Module:    os
--  Submodule: path
--  Purpose:   manipulation of strings representing filesystem paths
--  Reference: http://www.pythian.com/blog/gnu-basename-in-plsql/
--
--  Copyright (c) 2014-8 Roberto Reale
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




CREATE OR REPLACE PACKAGE NETTLE_OS_PATH IS

    --  emulate GNU basename(1) and dirname(1)

    FUNCTION BASENAME(
        p_full_path    IN VARCHAR2,
        p_suffix       IN VARCHAR2 DEFAULT NULL,
        p_separator    IN CHAR     DEFAULT '/'
    ) RETURN VARCHAR2;

    FUNCTION DIRNAME(
        p_full_path    IN VARCHAR2,
        p_separator    IN CHAR     DEFAULT '/'
    ) RETURN VARCHAR2;

END NETTLE_OS_PATH;
/


CREATE OR REPLACE PACKAGE BODY NETTLE_OS_PATH IS

    FUNCTION BASENAME(
        p_full_path    IN VARCHAR2,
        p_suffix       IN VARCHAR2 DEFAULT NULL,
        p_separator    IN CHAR     DEFAULT '/'
    ) RETURN VARCHAR2
    IS
        l_basename VARCHAR2(4000);
    BEGIN
        l_basename := SUBSTR(p_full_path, INSTR(p_full_path, p_separator, -1) + 1);
        IF p_suffix IS NOT NULL THEN
            l_basename := SUBSTR(l_basename, 1, INSTR(l_basename, p_suffix, -1) - 1);
        END IF;

        RETURN l_basename;
    END BASENAME;


    FUNCTION DIRNAME(
        p_full_path    IN VARCHAR2,
        p_separator    IN CHAR     DEFAULT '/'
    ) RETURN VARCHAR2
    IS
        l_dirname VARCHAR2(4000);
    BEGIN
        l_dirname := SUBSTR(p_full_path, 0, INSTR(p_full_path, p_separator, -1) - 1);

        RETURN l_dirname;
    END DIRNAME;

END NETTLE_OS_PATH;
/

--  ex: ts=4 sw=4 et filetype=sql
