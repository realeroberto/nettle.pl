--------------------------------------------------------------------------------
--
--  A PL/SQL chrestomathy
-- 
--  Module:    misc
--  Submodule: drop_many
--  Purpose:   dropping many interrelated objects
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



--  Note: We must have been granted the ALTER ANY TABLE, DROP ANY TABLE,
--        CREATE ANY INDEX and DROP ANY INDEX privileges.


CREATE OR REPLACE PACKAGE DROP_MANY AS

    PROCEDURE DROP_CONSTRAINTS(
        p_schema                IN VARCHAR2,
        p_table_expr            IN VARCHAR2,
        p_dry_run               IN BOOLEAN DEFAULT FALSE);

    PROCEDURE DROP_TABLES(
        p_schema                IN VARCHAR2,
        p_table_expr            IN VARCHAR2,
        p_purge                 IN BOOLEAN DEFAULT FALSE,
        p_dry_run               IN BOOLEAN DEFAULT FALSE);
    
END DROP_MANY;
/


CREATE OR REPLACE PACKAGE BODY DROP_MANY AS

    PROCEDURE DISABLE_CONSTRAINTS(
        p_schema                IN VARCHAR2,
        p_table_expr            IN VARCHAR2,
        p_dry_run               IN BOOLEAN DEFAULT FALSE)

    IS

        NO_SUCH_CONSTRAINT EXCEPTION;
        PRAGMA EXCEPTION_INIT(NO_SUCH_CONSTRAINT, -2431);

        TYPE l_constr_refcur_t  IS REF CURSOR;
        l_constr_refcur         l_constr_refcur_t;
        l_dml_stmt              VARCHAR2(4000);
        l_ddl_stmt              VARCHAR2(4000);
        l_table_name            VARCHAR2(30);
        l_constraint_name       VARCHAR2(30);

    BEGIN

        l_dml_stmt :=
            'SELECT c.table_name, c.constraint_name '||
            'FROM DBA_CONSTRAINTS c JOIN DBA_TABLES t ON c.table_name = t.table_name '||
            'WHERE t.owner = '''||p_schema||''' AND t.table_name LIKE '''||p_table_expr||''' '||
            'AND c.status = ''ENABLED''' ||
            'ORDER BY c.constraint_type DESC';
            
        OPEN l_constr_refcur FOR l_dml_stmt;

        LOOP
            FETCH l_constr_refcur INTO l_table_name, l_constraint_name;
            EXIT WHEN l_constr_refcur%NOTFOUND;

            l_ddl_stmt := 'ALTER TABLE "'||p_schema||'"."'||l_table_name||'" DISABLE CONSTRAINT "'||l_constraint_name||'"';
            
            DBMS_OUTPUT.PUT_LINE(l_ddl_stmt);
            IF NOT p_dry_run THEN
                DBMS_UTILITY.EXEC_DDL_STATEMENT(l_ddl_stmt);
            END IF;

        END LOOP;
            
        CLOSE l_constr_refcur;
    
    EXCEPTION
        WHEN NO_SUCH_CONSTRAINT THEN
            --  ORA-02431: cannot disable constraint - no such constraint
            NULL;

    END DISABLE_CONSTRAINTS;
    
    
    PROCEDURE DROP_CONSTRAINTS(
        p_schema                IN VARCHAR2,
        p_table_expr            IN VARCHAR2,
        p_dry_run               IN BOOLEAN DEFAULT FALSE)

    IS

        NO_SUCH_CONSTRAINT EXCEPTION;
        PRAGMA EXCEPTION_INIT(NO_SUCH_CONSTRAINT, -2443);

        TYPE l_constr_refcur_t  IS REF CURSOR;
        l_constr_refcur         l_constr_refcur_t;
        l_dml_stmt              VARCHAR2(4000);
        l_ddl_stmt              VARCHAR2(4000);
        l_table_name            VARCHAR2(30);
        l_constraint_name       VARCHAR2(30);

    BEGIN

        l_dml_stmt :=
            'SELECT c.table_name, c.constraint_name '||
            'FROM DBA_CONSTRAINTS c JOIN DBA_TABLES t ON c.table_name = t.table_name '||
            'WHERE t.owner = '''||p_schema||''' AND t.table_name LIKE '''||p_table_expr||''' '||
            'ORDER BY c.constraint_type DESC';
            
        OPEN l_constr_refcur FOR l_dml_stmt;

        LOOP
            FETCH l_constr_refcur INTO l_table_name, l_constraint_name;
            EXIT WHEN l_constr_refcur%NOTFOUND;

            l_ddl_stmt := 'ALTER TABLE "'||p_schema||'"."'||l_table_name||'" DROP CONSTRAINT "'||l_constraint_name||'"';
            
            DBMS_OUTPUT.PUT_LINE(l_ddl_stmt);
            IF NOT p_dry_run THEN
                DBMS_UTILITY.EXEC_DDL_STATEMENT(l_ddl_stmt);
            END IF;

        END LOOP;
            
        CLOSE l_constr_refcur;

    EXCEPTION
        WHEN NO_SUCH_CONSTRAINT THEN
            --  ORA-02443: Cannot drop constraint - nonexistent constraint
            NULL;
    
    END DROP_CONSTRAINTS;


    PROCEDURE DROP_TABLES(
        p_schema                IN VARCHAR2,
        p_table_expr            IN VARCHAR2,
        p_purge                 IN BOOLEAN DEFAULT FALSE,
        p_dry_run               IN BOOLEAN DEFAULT FALSE)

    IS

        TYPE l_table_refcur_t   IS REF CURSOR;
        l_table_refcur          l_table_refcur_t;
        l_dml_stmt              VARCHAR2(4000);
        l_ddl_stmt              VARCHAR2(4000);
        l_table_name            VARCHAR2(30);
        l_purge_clause          VARCHAR2(5) := '';

    BEGIN

        DISABLE_CONSTRAINTS(p_schema, p_table_expr, p_dry_run);
        DROP_CONSTRAINTS(p_schema, p_table_expr, p_dry_run);
        
        IF p_purge THEN
            l_purge_clause := 'PURGE';
        END IF;

        l_dml_stmt :=
            'SELECT table_name FROM DBA_TABLES '||
            'WHERE owner = '''||p_schema||''' AND table_name LIKE '''||p_table_expr||'''';
            
        OPEN l_table_refcur FOR l_dml_stmt;

        LOOP
            FETCH l_table_refcur INTO l_table_name;
            EXIT WHEN l_table_refcur%NOTFOUND;

            l_ddl_stmt := 'DROP TABLE "'||p_schema||'"."'||l_table_name||'" '||l_purge_clause;

            DBMS_OUTPUT.PUT_LINE(l_ddl_stmt);
            IF NOT p_dry_run THEN
                DBMS_UTILITY.EXEC_DDL_STATEMENT(l_ddl_stmt);
            END IF;

        END LOOP;
            
        CLOSE l_table_refcur;

    END DROP_TABLES;

END DROP_MANY;
/

--  ex: ts=4 sw=4 et filetype=sql
