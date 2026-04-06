--Copyright (C) 2025  Altera Corporation. All rights reserved.
--Your use of Altera Corporation's design tools, logic functions 
--and other software and tools, and any partner logic 
--functions, and any output files from any of the foregoing 
--(including device programming or simulation files), and any 
--associated documentation or information are expressly subject 
--to the terms and conditions of the Altera Program License 
--Subscription Agreement, the Altera Quartus Prime License Agreement,
--the Altera IP License Agreement, or other applicable license
--agreement, including, without limitation, that your use is for
--the sole purpose of programming logic devices manufactured by
--Altera and sold by Altera or its authorized distributors.  Please
--refer to the Altera Software License Subscription Agreements 
--on the Quartus Prime software download page.


FUNCTION RAM_IP 
(
	address_a[15..0],
	address_b[15..0],
	clock_a,
	clock_b,
	data_a[7..0],
	data_b[7..0],
	wren_a,
	wren_b
)

RETURNS (
	q_a[7..0],
	q_b[7..0]
);
