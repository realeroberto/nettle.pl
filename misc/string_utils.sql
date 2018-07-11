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

create or replace PACKAGE BODY                "PICOF_QUERY" AS

  -- JOIN:
  -- simula il comportamento della funzione join del PERL
  -- riceve un array di stringhe e restituisce un'unica stringa data dalla concatenazione
  -- degli elementi dell'array
  PROCEDURE JOIN(separator    IN VARCHAR2 DEFAULT '|',
                 stringlist   IN stringarr,
                 joinedstring OUT VARCHAR2) IS
    buffer  VARCHAR2(32767) := '';
    counter INTEGER;
  BEGIN

    IF stringlist.COUNT > 0 THEN
      buffer  := stringlist(1);
      counter := length(stringlist(1));
    END IF;

    FOR i IN 2 .. stringlist.COUNT LOOP
      counter := counter + length(stringlist(i)) + 1;
      IF counter > 32767 THEN
        raise_application_error(-20000,
                                'picof_query.join::the resulting joined string is too long');
      END IF;
      buffer := buffer || JOIN.separator || stringlist(i);
    END LOOP;

    joinedstring := buffer;

  END JOIN;

  -- SPLIT:
  -- simula il comportamento della funzione split del PERL
  -- riceve un varchar o un clob e restituisce un array di stringhe ricavato
  -- in base ad un carattere separatore
  --      Parametri:
  --
  --         string_in (clob_in)       => stringa o clob da 'spacchettare'
  --          ch_sep                   => carattere separatore(uno o pi? caratteri), se non valorizzato si opera utilizzando
  --                                   le dimensioni del buffer_len
  --      buffer_len                   => specifica la lunghezza dei pacchetti, di default ? 32767
  --       res_array                   => array di pacchetti risultato
  --     want_ch_sep                   => se si vuole che rimanga il carattere separatore negli array ,default true
  -- --------------------------------------------------------------------------------------------

  PROCEDURE split(string_in   IN VARCHAR2,
                  separator   IN VARCHAR2 DEFAULT NULL,
                  buffer_len  IN BINARY_INTEGER DEFAULT 32767,
                  want_ch_sep IN BOOLEAN DEFAULT FALSE,
                  stringlist  OUT stringarr) IS
    offset      NUMBER := 1;
    n_cicli     INTEGER;
    step        BINARY_INTEGER := 0;
    position    INTEGER := 0;
    i           INTEGER := 0;
    l_separator INTEGER := 0;
  BEGIN
    IF separator IS NULL THEN
      --se non si vuole effettuare lo 'spacchettamento'
      --con la ricerca del separatore ma mediante il "buffer_len"
      IF buffer_len > 32767 OR buffer_len < 0 THEN
        raise_application_error(-20000,
                                'ecw_str:split::wrong dimension of the buffer');
      END IF;

      n_cicli := trunc(length(string_in) / buffer_len) + 1;
      FOR i IN 1 .. n_cicli LOOP
        stringlist(i) := substr(string_in, offset, buffer_len);
        offset := offset + buffer_len;
      END LOOP;
    ELSE
      --se viene fornito il carattere separatore
      i           := 1;
      l_separator := length(separator);
      LOOP
        --      exit when offset>=length(string_in);
        EXIT WHEN offset > length(string_in);

        position := instr(string_in, separator, offset);
        --controlla se non ha trovato il separatore
        IF position = 0 THEN
          step := length(string_in) - offset + 1;
          IF step > 32767 THEN
            step := 32767;
          END IF;
        ELSE
          IF (position - offset) > 32767 THEN
            step := 32767;
          ELSE
            IF want_ch_sep THEN
              step := position - offset + l_separator;
            ELSE
              step := position - offset;
            END IF;
          END IF;
        END IF;
        stringlist(i) := substr(string_in, offset, step);

        IF position = 0 THEN
          offset := offset + step;
        ELSE
          offset := position + l_separator;
        END IF;

        i := i + 1;

      END LOOP;
    END IF;
  END split;

--  ex: ts=4 sw=4 et filetype=sql
