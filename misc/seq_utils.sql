--------------------------------------------------------------------------------
--
--  A PL/SQL chrestomathy
-- 
--  Module:    misc
--  Submodule: seq_utils
--  Purpose:   utilities for sequences
--  Reference: http://stackoverflow.com/questions/1426647/
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




CREATE OR REPLACE PACKAGE SEQ_UTILS

    --  Reset a sequence to match a given "primary key"

    PROCEDURE INCREASE_TO_MATCH_PK(
        p_schema      IN VARCHAR2,
        p_table       IN VARCHAR2,
        p_column      IN VARCHAR2,
        p_sequence    IN VARCHAR2);

END SEQ_UTILS;


CREATE OR REPLACE PACKAGE BODY SEQ_UTILS

    PROCEDURE INCREASE_TO_MATCH_PK(
        p_schema      IN VARCHAR2,
        p_table       IN VARCHAR2,
        p_column      IN VARCHAR2,
        p_sequence    IN VARCHAR2)
    IS
        l_seq_next    PLS_INTEGER;
        l_delta       PLS_INTEGER;
        l_sql_stmt    VARCHAR2(4000);
    BEGIN
        --  Fetch the next value from the sequence
        l_sql_stmt := 'SELECT "'||p_schema||'"."'||p_sequence||'".nextval FROM dual';
        EXECUTE IMMEDIATE l_sql_stmt INTO l_seq_next;

        --  Calculate the gap to be filled
        l_sql_stmt := 'SELECT (NVL(MAX("'||p_column||'"), 0) - :1) + 1 FROM "'||p_schema||'"."'||p_table||'"';
        EXECUTE IMMEDIATE l_sql_stmt INTO l_delta USING l_seq_next;

        IF l_delta > 0 THEN
            --  Set the sequence increment value to L_DELTA
            l_sql_stmt := 'ALTER SEQUENCE "'||p_schema||'"."'||p_sequence||'" INCREMENT BY '||l_delta;
            DBMS_UTILITY.EXEC_DDL_STATEMENT(l_sql_stmt);

            --  Bump the sequence
            l_sql_stmt := 'SELECT "'||p_schema||'"."'||p_sequence||'".nextval FROM dual';
            --  The sequence won't increment unless we store the new value (hence the INTO clause)
            --  cf. http://stackoverflow.com/questions/15407456/
            EXECUTE IMMEDIATE l_sql_stmt INTO l_seq_next;

            --  Reset the sequence increment value to 1
            l_sql_stmt := 'ALTER SEQUENCE "'||p_schema||'"."'||p_sequence||'" INCREMENT BY 1';
            DBMS_UTILITY.EXEC_DDL_STATEMENT(l_sql_stmt);
        END IF;
    END INCREASE_TO_MATCH_PK;

END SEQ_UTILS;
/

--  ex: ts=4 sw=4 et filetype=sql
