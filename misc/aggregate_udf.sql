--------------------------------------------------------------------------------
--
--  A PL/SQL chrestomathy
-- 
--  Module:    misc
--  Submodule: aggregate_udf
--  Purpose:   some user-defined aggregate functions
--  Reference: http://viralpatel.net/blogs/row-data-multiplication-in-oracle/
--
--  Copyright (c) 2015 Roberto Reale
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



CREATE OR REPLACE PACKAGE AGGREGATE_UDF IS

    FUNCTION PRODUCT(
        p_schema      IN VARCHAR2,
        p_table       IN VARCHAR2,
        p_column      IN VARCHAR2)
    RETURN NUMBER;

END AGGREGATE_UDF;
/


CREATE OR REPLACE PACKAGE BODY AGGREGATE_UDF IS

    FUNCTION PRODUCT(
        p_schema      IN VARCHAR2,
        p_table       IN VARCHAR2,
        p_column      IN VARCHAR2)
    RETURN NUMBER
    IS
        l_product    NUMBER;
        l_sign       NUMBER;
        l_sql_stmt   VARCHAR2(4000);
    BEGIN
        --  calculate the absolute product by means of the EXP() transform
        l_sql_stmt := '
            SELECT
                EXP(SUM(LN(ABS("'||p_column||'"))))
            FROM
                "'||p_schema||'"."'||p_table||'"';
        EXECUTE IMMEDIATE l_sql_stmt INTO l_product;
            
        --  calculate the sign of the product
        l_sql_stmt := '
            SELECT
                CASE
                    MOD(COUNT(*), 2) WHEN 0 THEN 1
                    ELSE -1
                END
            FROM
                "'||p_schema||'"."'||p_table||'"
            WHERE
                "'||p_column||'" < 0';
        EXECUTE IMMEDIATE l_sql_stmt INTO l_sign;

        --  return the product together with its sign
        RETURN l_product * l_sign;
    END PRODUCT;

END AGGREGATE_UDF;
/

--  ex: ts=4 sw=4 et filetype=sql
