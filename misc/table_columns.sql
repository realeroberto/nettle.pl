--------------------------------------------------------------------------------
--
--  A PL/SQL chrestomathy
-- 
--  Module:    misc
--  Submodule: table_columns
--  Purpose:   get an ordered list of a table's columns
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



CREATE OR REPLACE PACKAGE TABLE_COLUMNS AS
    
    FUNCTION GET_TAB_COLS_LIST (
        p_table_name   IN  VARCHAR2,
        p_owner        IN  VARCHAR2 DEFAULT NULL)
    RETURN VARCHAR2;

END TABLE_COLUMNS;
/


CREATE OR REPLACE PACKAGE BODY TABLE_COLUMNS AS

    --  emulates 11g's WM_CONCAT()

    FUNCTION CONCAT_LIST (
        p_cursor       IN  SYS_REFCURSOR,
        p_delimiter    IN  VARCHAR2 DEFAULT ',')
        RETURN  VARCHAR2
    IS
        l_return  VARCHAR2(32767); 
        l_temp    VARCHAR2(32767);
    BEGIN
        LOOP
            FETCH p_cursor
            INTO  l_temp;

            EXIT WHEN p_cursor%NOTFOUND;
            
            l_return := l_return || p_delimiter || l_temp;
        END LOOP;
        RETURN LTRIM(l_return, p_delimiter);

    END CONCAT_LIST;


    FUNCTION GET_TAB_COLS_LIST (
        p_table_name   IN  VARCHAR2,
        p_owner        IN  VARCHAR2 DEFAULT NULL)
        RETURN VARCHAR2
    IS
        l_col_cursor   SYS_REFCURSOR;
        l_col_list     VARCHAR2(32767); 
    BEGIN
        OPEN l_col_cursor FOR SELECT column_name
            FROM all_tab_columns
            WHERE
                (p_owner IS NOT NULL AND owner = p_owner 
                    OR p_owner IS NULL and owner = SYS_CONTEXT('USERENV', 'SESSION_SCHEMA'))
                AND table_name = p_table_name
            ORDER BY column_id;

            l_col_list := CONCAT_LIST(l_col_cursor);

        CLOSE l_col_cursor;

        RETURN l_col_list;

    END GET_TAB_COLS_LIST;

END TABLE_COLUMNS;
/

--  ex: ts=4 sw=4 et filetype=sql
