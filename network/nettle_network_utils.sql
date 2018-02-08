--------------------------------------------------------------------------------
--
--  A PL/SQL chrestomathy
-- 
--  Module:    network
--  Submodule: utils
--  Purpose:   utility procedures and functions for manipulating IP addresses
--
--  Copyright (c) 2014-8 Roberto Reale
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



CREATE OR REPLACE PACKAGE NETTLE_NETWORK_UTILS
AS

	FUNCTION IP_IN_SUBNET (
		p_ip_address IN VARCHAR2, p_subnet IN VARCHAR2)
		RETURN BOOLEAN;

	FUNCTION INT_TO_IP(ip_address IN INTEGER) RETURN VARCHAR2;
	
	FUNCTION IP_TO_INT(ip_string IN VARCHAR2) RETURN INTEGER;

END NETTLE_NETWORK_UTILS;
/


CREATE OR REPLACE PACKAGE BODY NETTLE_NETWORK_UTILS
AS

	FUNCTION INT_TO_BIN (p_num IN INTEGER) RETURN VARCHAR2
	IS
		l_bin    VARCHAR2(64);
		l_num_2  NUMBER := p_num;
	BEGIN
		WHILE (l_num_2 > 0) LOOP
			l_bin   := MOD(l_num_2, 2) || l_bin;
			l_num_2 := TRUNC(l_num_2 / 2);
		END LOOP;
		
		RETURN l_bin;
	
	END INT_TO_BIN;


	--  cf. http://stackoverflow.com/questions/776355/
	
	FUNCTION BIT_SHIFT_RIGHT (
		p_bin IN VARCHAR2, p_shift IN NUMBER DEFAULT NULL)
		RETURN VARCHAR2
	IS
		l_len   NUMBER;
		l_shift NUMBER;
	BEGIN
		l_shift := NVL(p_shift, 1);
		l_len := LENGTH(p_bin);
		IF (l_len <= 0) THEN
			RETURN NULL;
		END IF; 
		IF (l_shift > l_len) THEN
			l_shift := l_len;
		END IF;

		RETURN LPAD(SUBSTR(p_bin, 1, l_len - l_shift), l_len, '0'); 
	END BIT_SHIFT_RIGHT;

	
	FUNCTION IP_IN_SUBNET (
		p_ip_address IN VARCHAR2, p_subnet IN VARCHAR2)
		RETURN BOOLEAN
	IS
		l_ip_addr              INTEGER;

		l_slash                INTEGER;
		l_subnet_addr_s        VARCHAR2(30);
		l_subnet_len_s         VARCHAR2(2);
		l_subnet_addr          INTEGER;
		l_subnet_len           INTEGER;
		
		l_ip_addr_shifted      INTEGER;
		l_subnet_addr_shifted  INTEGER;
		
		l_shift                INTEGER;

	BEGIN
		IF p_ip_address IS NULL OR p_subnet IS NULL
		THEN
			RETURN FALSE;
		END IF;

		l_ip_addr := IP_TO_INT(p_ip_address);

		l_slash         := INSTR(p_subnet, '/');
		l_subnet_addr_s := SUBSTR(p_subnet, 1, l_slash - 1);
		l_subnet_len_s  := SUBSTR(p_subnet, l_slash + 1);
		l_subnet_addr   := IP_TO_INT(l_subnet_addr_s);
		l_subnet_len    := TO_NUMBER(l_subnet_len_s);

		l_shift := 32 - l_subnet_len;
		
		l_ip_addr_shifted := BIT_SHIFT_RIGHT(INT_TO_BIN(l_ip_addr), l_shift);
		l_subnet_addr_shifted := BIT_SHIFT_RIGHT(INT_TO_BIN(l_subnet_addr), l_shift);
		
		RETURN l_ip_addr_shifted = l_subnet_addr_shifted;
		
	END IP_IN_SUBNET;


	--  cf. http://stackoverflow.com/questions/1084413/
	
	FUNCTION INT_TO_IP(ip_address IN INTEGER) RETURN VARCHAR2 IS
		v8 VARCHAR2(8);
	BEGIN
		-- 1. convert the integer into hexadecimal representation
		v8 := TO_CHAR(ip_address, 'FM0000000X');
		-- 2. convert each XX portion back into decimal
		RETURN to_number(substr(v8,1,2),'XX')
			|| '.' || to_number(substr(v8,3,2),'XX')
			|| '.' || to_number(substr(v8,5,2),'XX')
			|| '.' || to_number(substr(v8,7,2),'XX');
	END INT_TO_IP;

	
	--  cf. http://stackoverflow.com/questions/1084413/
	
	FUNCTION IP_TO_INT(ip_string IN VARCHAR2) RETURN INTEGER IS
		d1 INTEGER;
		d2 INTEGER;
		d3 INTEGER;
		q1 VARCHAR2(3);
		q2 VARCHAR2(3);
		q3 VARCHAR2(3);
		q4 VARCHAR2(3);
		v8 VARCHAR2(8);
	BEGIN
		-- 1. parse the input, e.g. '203.30.237.2'
		d1 := INSTR(ip_string,'.');     -- first dot
		d2 := INSTR(ip_string,'.',1,2); -- second dot
		d3 := INSTR(ip_string,'.',1,3); -- third dot
		q1 := SUBSTR(ip_string, 1, d1 - 1);           -- e.g. '203'
		q2 := SUBSTR(ip_string, d1 + 1, d2 - d1 - 1); -- e.g. '30'
		q3 := SUBSTR(ip_string, d2 + 1, d3 - d2 - 1); -- e.g. '237'
		q4 := SUBSTR(ip_string, d3 + 1);              -- e.g. '2'
		-- 2. convert to a hexadecimal string
		v8 := LPAD(TO_CHAR(TO_NUMBER(q1),'FMXX'),2,'0')
			|| LPAD(TO_CHAR(TO_NUMBER(q2),'FMXX'),2,'0')
			|| LPAD(TO_CHAR(TO_NUMBER(q3),'FMXX'),2,'0')
			|| LPAD(TO_CHAR(TO_NUMBER(q4),'FMXX'),2,'0');
		-- 3. convert to a decimal number
		RETURN TO_NUMBER(v8, 'FMXXXXXXXX');
	END IP_TO_INT;

END NETTLE_NETWORK_UTILS;
/


--  ex: ts=4 sw=4 et filetype=sql
