--------------------------------------------------------------------------------
--
--  A PL/SQL chrestomathy
-- 
--  Module:    network
--  Submodule: awr_date_interval
--  Purpose:   a wrapper around dbms_workload_repository.awr_report_text()
--             which supports dates
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



--  Note: We must have been granted SELECT on sys.dba_hist_snapshot and EXECUTE
--        on DBMS_WORKLOAD_REPOSITORY.

	
CREATE OR REPLACE PACKAGE AWR_DATE_INTERVAL
-- AUTHID DEFINER
AS
		
    FUNCTION AWR_REPORT_TEXT_DATE_INTERVAL(
        l_dbid       IN    NUMBER,
        l_inst_num   IN    NUMBER,
        l_b_date     IN    TIMESTAMP,
        l_e_date     IN    TIMESTAMP,
        l_options    IN    NUMBER DEFAULT 0)
    RETURN awrrpt_text_type_table PIPELINED;

END AWR_DATE_INTERVAL;
/


CREATE OR REPLACE PACKAGE BODY AWR_DATE_INTERVAL AS
	
    FUNCTION AWR_REPORT_TEXT_DATE_INTERVAL(
        l_dbid       IN    NUMBER,
        l_inst_num   IN    NUMBER,
        l_b_date     IN    TIMESTAMP,
        l_e_date     IN    TIMESTAMP,
        l_options    IN    NUMBER DEFAULT 0)
    RETURN awrrpt_text_type_table PIPELINED
    IS
        l_bid   NUMBER;
        l_eid   NUMBER;
    BEGIN

        SELECT snap_id INTO l_bid FROM (
            SELECT snap_id FROM sys.dba_hist_snapshot
            WHERE
                dbid = l_dbid
                AND instance_number = l_inst_num
                AND begin_interval_time > GREATEST(startup_time, l_b_date)
            ORDER BY begin_interval_time ASC
        ) WHERE rownum <= 1;
      
        SELECT snap_id INTO l_eid FROM (
            SELECT snap_id FROM sys.dba_hist_snapshot
            WHERE
                dbid = l_dbid
                AND instance_number = l_inst_num
                AND startup_time < begin_interval_time AND end_interval_time > l_e_date
            ORDER by snap_id DESC
        ) WHERE rownum <= 1;

        FOR c IN (
            SELECT t.output
                FROM TABLE(DBMS_WORKLOAD_REPOSITORY.AWR_REPORT_TEXT(l_dbid, l_inst_num, l_bid, l_eid, l_options)) t
        )
        LOOP
            PIPE ROW(awrrpt_text_type(c.output));
        END LOOP;
    END AWR_REPORT_TEXT_DATE_INTERVAL;

END AWR_DATE_INTERVAL;
/

--  ex: ts=4 sw=4 et filetype=sql
