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

    --  emulates MySQL's TIME_TO_SEC()

    FUNCTION TIME_TO_SEC(p_ts IN TIMESTAMP) RETURN NUMBER;

END TIME_FUNCTIONS;
/


CREATE OR REPLACE PACKAGE BODY TIME_FUNCTIONS AS

    --  cf. e.g. the discussion at https://community.oracle.com/message/10636651

    FUNCTION TIME_TO_SEC(p_ts IN TIMESTAMP) RETURN NUMBER IS
    BEGIN
        RETURN
            EXTRACT(DAY    FROM p_ts) * 24 * 60 * 60 +
            EXTRACT(HOUR   FROM p_ts) * 60 * 60 +
            EXTRACT(MINUTE FROM p_ts) * 60 +
            EXTRACT(SECOND FROM p_ts);
    END TIME_TO_SEC;

END TIME_FUNCTIONS;
/

--  ex: ts=4 sw=4 et filetype=sql
