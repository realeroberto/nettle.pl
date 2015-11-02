--------------------------------------------------------------------------------
--
--  A PL/SQL chrestomathy
-- 
--  Module:    misc
--  Submodule: build_sql_text
--  Purpose:   piecewise glueing of sql_text field in gv$sqltext
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


--  Note: We must have been granted SELECT powers on gv_$sqltext.


CREATE OR REPLACE PACKAGE SQL_TEXT
    AUTHID CURRENT_USER
AS
    FUNCTION BUILD_SQL_TEXT (
        p_inst_id   IN   gv$sqltext.inst_id%TYPE,
        p_address   IN   gv$sqltext.address%TYPE
    ) RETURN VARCHAR2;

    FUNCTION BUILD_SQL_TEXT (
        p_inst_id      IN   gv$sqltext.inst_id%TYPE,
        p_hash_value   IN   gv$sqltext.hash_value%TYPE
    ) RETURN VARCHAR2;

    FUNCTION BUILD_SQL_TEXT (
        p_inst_id   IN   gv$sqltext.inst_id%TYPE,
        p_sql_id    IN   gv$sqltext.sql_id%TYPE
    ) RETURN VARCHAR2;

END SQL_TEXT;
/


CREATE OR REPLACE PACKAGE BODY SQL_TEXT
AS

    FUNCTION BUILD_SQL_TEXT (
        p_inst_id   IN   gv$sqltext.inst_id%TYPE,
        p_address   IN   gv$sqltext.address%TYPE
    ) RETURN VARCHAR2
    IS
        l_text  LONG;
    BEGIN
        FOR x IN (
            SELECT
                sql_text FROM gv$sqltext
            WHERE
                inst_id = p_inst_id AND address = p_address
            ORDER BY piece
        )

        LOOP
            l_text := l_text || x.sql_text;
            EXIT WHEN LENGTH(l_text) > 4000;
        END LOOP;

        RETURN SUBSTR(l_text, 1, 4000);
    END BUILD_SQL_TEXT;


    FUNCTION BUILD_SQL_TEXT (
        p_inst_id      IN   gv$sqltext.inst_id%TYPE,
        p_hash_value   IN   gv$sqltext.hash_value%TYPE
    ) RETURN VARCHAR2
    IS
        l_text  LONG;
    BEGIN
        FOR x IN (
            SELECT
                sql_text FROM gv$sqltext
            WHERE
                inst_id = p_inst_id AND hash_value = p_hash_value
            ORDER BY piece
        )

        LOOP
            l_text := l_text || x.sql_text;
            EXIT WHEN LENGTH(l_text) > 4000;
        END LOOP;

        RETURN SUBSTR(l_text, 1, 4000);
    END BUILD_SQL_TEXT;


    FUNCTION BUILD_SQL_TEXT (
        p_inst_id   IN   gv$sqltext.inst_id%TYPE,
        p_sql_id    IN   gv$sqltext.sql_id%TYPE
    ) RETURN VARCHAR2
    IS
        l_text  LONG;
    BEGIN
        FOR x IN (
            SELECT
                sql_text FROM gv$sqltext
            WHERE
              inst_id = p_inst_id AND p_sql_id = sql_id
            ORDER BY piece
        )

        LOOP
            l_text := l_text || x.sql_text;
            EXIT WHEN LENGTH(l_text) > 4000;
        END LOOP;

        RETURN SUBSTR(l_text, 1, 4000);
    END BUILD_SQL_TEXT;

END SQL_TEXT;
/

--  ex: ts=4 sw=4 et filetype=sql
