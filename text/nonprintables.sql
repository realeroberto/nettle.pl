--------------------------------------------------------------------------------
--
--  A PL/SQL chrestomathy
-- 
--  Module:    text
--  Submodule: nonprintables
--  Purpose:   detecting and amending nonprintable strings
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



CREATE OR REPLACE PACKAGE NONPRINTABLES

    AUTHID CURRENT_USER

AS

    PROCEDURE DETECT_NONPRINTABLE_ROWS(
        p_schema                IN VARCHAR2,
        p_table_expr            IN VARCHAR2,
        p_col_expr              IN VARCHAR2,
        p_tolerate_newlines     IN BOOLEAN DEFAULT TRUE,
        p_enable_expressions    IN BOOLEAN DEFAULT FALSE,
        p_enable_debug          IN BOOLEAN DEFAULT FALSE);

    PROCEDURE AMEND_NONPRINTABLE_ROW(
        p_schema             IN VARCHAR2,
        p_table_name         IN VARCHAR2,
        p_col_name           IN VARCHAR2,
        p_rowid              UROWID,
        p_tolerate_newlines  IN BOOLEAN DEFAULT TRUE);

END NONPRINTABLES;
/


CREATE OR REPLACE PACKAGE BODY NONPRINTABLES AS

    PROCEDURE DEBUG(
        p_msg            IN VARCHAR2,
        p_enable_debug   IN BOOLEAN
    )
    IS
    BEGIN
        IF p_enable_debug THEN
            DBMS_OUTPUT.PUT_LINE('DEBUG: ' || p_msg);
        END IF;
    END DEBUG;


    PROCEDURE DETECT_NONPRINTABLE_ONEROW(
        p_schema                IN VARCHAR2,
        p_table_name            IN VARCHAR2,
        p_col_name              IN VARCHAR2,
        p_tolerate_newlines     IN BOOLEAN DEFAULT TRUE,
        p_enable_debug          IN BOOLEAN DEFAULT FALSE
    )

    IS

        TYPE l_rowids_refcur_t  IS REF CURSOR;
        l_rowids_refcur         l_rowids_refcur_t;
        l_sql_stmt              VARCHAR2(4000);
        l_rowid                 UROWID;

    BEGIN

        l_sql_stmt := 'SELECT rowid FROM "'||p_schema||'"."'||p_table_name||'"';

        IF p_tolerate_newlines THEN
            l_sql_stmt := l_sql_stmt ||' WHERE REGEXP_INSTR(REPLACE(REPLACE("'||p_col_name||'", CHR(10)), CHR(13)), ''[^[:print:]]'') > 0';
        ELSE
            l_sql_stmt := l_sql_stmt ||' WHERE REGEXP_INSTR("'||p_col_name||'", ''[^[:print:]]'') > 0';
        END IF;

        DEBUG(l_sql_stmt, p_enable_debug);
    
        OPEN l_rowids_refcur FOR l_sql_stmt;

        LOOP
            FETCH l_rowids_refcur INTO l_rowid;
            EXIT WHEN l_rowids_refcur%NOTFOUND;
            dbms_output.put_line('One row was found in table '|| p_schema||'.'||p_table_name ||' with ROWID = '||l_rowid);
            dbms_output.put_line('To select it please issue: SELECT * FROM "'||p_schema||'"."'||p_table_name||'" WHERE ROWID = '''||l_rowid||''';');
        END LOOP;
        
        CLOSE l_rowids_refcur;

    END DETECT_NONPRINTABLE_ONEROW;


    PROCEDURE DETECT_NONPRINTABLE_ROWS(
        p_schema                IN VARCHAR2,
        p_table_expr            IN VARCHAR2,
        p_col_expr              IN VARCHAR2,
        p_tolerate_newlines     IN BOOLEAN DEFAULT TRUE,
        p_enable_expressions    IN BOOLEAN DEFAULT FALSE,
        p_enable_debug          IN BOOLEAN DEFAULT FALSE)

    IS

        TYPE l_rowids_refcur_t  IS REF CURSOR;
        l_tab_col_refcur        l_rowids_refcur_t;
        l_sql_stmt              VARCHAR2(4000);
        l_table_name            VARCHAR2(30);
        l_col_name              VARCHAR2(30);

    BEGIN

        IF p_enable_expressions THEN
            l_sql_stmt :=
                'SELECT table_name, column_name FROM DBA_TAB_COLUMNS WHERE owner = '''||p_schema||''''
                ||' AND table_name LIKE '''||p_table_expr||''' AND column_name LIKE '''||p_col_expr||'''';
                
            DEBUG(l_sql_stmt, p_enable_debug);

            OPEN l_tab_col_refcur FOR l_sql_stmt;

            LOOP
                FETCH l_tab_col_refcur INTO l_table_name, l_col_name;
                EXIT WHEN l_tab_col_refcur%NOTFOUND;
                
                DETECT_NONPRINTABLE_ONEROW(p_schema, l_table_name, l_col_name, p_tolerate_newlines, p_enable_debug);
            END LOOP;
            
            CLOSE l_tab_col_refcur;

        ELSE
            DETECT_NONPRINTABLE_ONEROW(p_schema, p_table_expr, p_col_expr, p_tolerate_newlines, p_enable_debug);

        END IF;

    END DETECT_NONPRINTABLE_ROWS;


    PROCEDURE AMEND_NONPRINTABLE_ROW(
        p_schema             IN VARCHAR2,
        p_table_name         IN VARCHAR2,
        p_col_name           IN VARCHAR2,
        p_rowid              UROWID,
        p_tolerate_newlines  IN BOOLEAN DEFAULT TRUE)

    IS

        l_sql_stmt        VARCHAR2(4000);
        l_dump_old_value  VARCHAR2(4000);
        l_dump_new_value  VARCHAR2(4000);

    BEGIN

        l_sql_stmt := 'SELECT DUMP("'||p_col_name||'") FROM "'||p_schema||'"."'||p_table_name||'" WHERE ROWID = '''||p_rowid||'''';
        EXECUTE IMMEDIATE l_sql_stmt INTO l_dump_old_value;
        
        l_sql_stmt := 'UPDATE "'||p_schema||'"."'||p_table_name||'" SET '||p_col_name||' = ';

        IF p_tolerate_newlines THEN
            l_sql_stmt := l_sql_stmt ||'REPLACE(REPLACE(REGEXP_REPLACE("'||p_col_name||'", ''[^[:print:]]'', ''''), CHR(10)), CHR(13))';
        ELSE
            l_sql_stmt := l_sql_stmt ||'REGEXP_REPLACE("'||p_col_name||'", ''[^[:print:]]'', '''')';
        END IF;
        
        l_sql_stmt := l_sql_stmt || ' WHERE ROWID = ''' || p_rowid || '''';
        
        EXECUTE IMMEDIATE l_sql_stmt;

        l_sql_stmt := 'SELECT DUMP("'||p_col_name||'") FROM "'||p_schema||'"."'||p_table_name||'" WHERE ROWID = '''||p_rowid||'''';
        EXECUTE IMMEDIATE l_sql_stmt INTO l_dump_new_value;
        
        DBMS_OUTPUT.PUT_LINE('Row successfully amended in table '||p_schema||'.'||p_table_name ||' on ROWID = '|| p_rowid);
        DBMS_OUTPUT.PUT_LINE('Old value was ' || l_dump_old_value);
        DBMS_OUTPUT.PUT_LINE('New value is  ' || l_dump_new_value);
        DBMS_OUTPUT.PUT_LINE('Please don''t forget to issue COMMIT.');

    EXCEPTION
        WHEN OTHERS THEN
            BEGIN
                DBMS_OUTPUT.PUT_LINE('An error occurred on updating row on ROWID = ' || p_rowid);
                RAISE;
            END;

    END AMEND_NONPRINTABLE_ROW;

END NONPRINTABLES;
/

--  ex: ts=4 sw=4 et filetype=sql
