--------------------------------------------------------------------------------
--
--  A PL/SQL chrestomathy
-- 
--  Module:    time
--  Submodule: time_functions
--  Purpose:   various functions for dealing with time
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


CREATE OR REPLACE PACKAGE TIME_FUNCTIONS AS

    --  cf. the discussion at https://community.oracle.com/message/4340069

    SUBTYPE unconstrained_ds IS INTERVAL DAY(9) TO SECOND(9);

    --  emulates MySQL's TIME_TO_SEC()

    FUNCTION TIME_TO_SEC(p_ds IN unconstrained_ds)
        RETURN NUMBER;

    FUNCTION FROM_UNIX_TIMESTAMP(p_ts IN NUMBER)
        RETURN TIMESTAMP WITH TIME ZONE;

    FUNCTION TO_UNIX_TIMESTAMP(p_ts IN TIMESTAMP WITH TIME ZONE)
        RETURN INTEGER;

    FUNCTION FROM_ADS_TIMESTAMP(p_ts IN NUMBER)
        RETURN TIMESTAMP WITH TIME ZONE;

    FUNCTION TO_ADS_TIMESTAMP(p_ts IN TIMESTAMP WITH TIME ZONE)
        RETURN INTEGER;

END TIME_FUNCTIONS;
/


CREATE OR REPLACE PACKAGE BODY TIME_FUNCTIONS AS

    --  cf. e.g.:
    --      https://community.oracle.com/message/10636651
    --      http://stackoverflow.com/questions/11617962

    FUNCTION TIME_TO_SEC(p_ds IN unconstrained_ds)
        RETURN NUMBER
    IS
    BEGIN
        RETURN
            EXTRACT(DAY    FROM p_ds) * 24 * 60 * 60 +
            EXTRACT(HOUR   FROM p_ds) * 60 * 60 +
            EXTRACT(MINUTE FROM p_ds) * 60 +
            EXTRACT(SECOND FROM p_ds);
    END TIME_TO_SEC;


    FUNCTION FROM_UNIX_TIMESTAMP(p_ts IN NUMBER)
        RETURN TIMESTAMP WITH TIME ZONE
    IS
    BEGIN
        RETURN
            TO_TIMESTAMP_TZ('1970-01-01 UTC', 'yyyy-mm-dd TZR') +
            NUMTODSINTERVAL(p_ts / 3600 / 24, 'DAY');
    END FROM_UNIX_TIMESTAMP;


    FUNCTION TO_UNIX_TIMESTAMP(p_ts IN TIMESTAMP WITH TIME ZONE)
        RETURN INTEGER
    IS
    BEGIN
        RETURN
            TIME_TO_SEC(
                (p_ts - to_timestamp_tz('1970-01-01 UTC', 'yyyy-mm-dd TZR'))
            );
    END TO_UNIX_TIMESTAMP;


    FUNCTION FROM_ADS_TIMESTAMP(p_ts IN NUMBER)
        RETURN TIMESTAMP WITH TIME ZONE
    IS
    BEGIN
        RETURN
            TO_TIMESTAMP_TZ('1601-01-01 UTC', 'yyyy-mm-dd TZR') +
            NUMTODSINTERVAL(p_ts / POWER(10, 7) / 3600 / 24, 'DAY');
    END FROM_ADS_TIMESTAMP;


    FUNCTION TO_ADS_TIMESTAMP(p_ts IN TIMESTAMP WITH TIME ZONE)
        RETURN INTEGER
    IS
    BEGIN
        RETURN
            TIME_TO_SEC(
                (p_ts - to_timestamp_tz('1601-01-01 UTC', 'yyyy-mm-dd TZR'))
            ) * POWER(10, 7);
    END TO_ADS_TIMESTAMP;

END TIME_FUNCTIONS;
/

--  ex: ts=4 sw=4 et filetype=sql
