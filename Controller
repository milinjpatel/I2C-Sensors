library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
entity Controller is
	port(clk, reset: in std_logic;
		  WADD: out std_logic_vector(4 downto 0);
		  N_Byte: out std_logic_vector(5 downto 0);
		  dev_add: out std_logic_vector(6 downto 0);
		  dwr, R_Pointer, DIN: out std_logic_vector(7 downto 0);
		  drd: in std_logic_vector(7 downto 0);
		  done, ready, ack_e: in std_logic;
		  W, go, rw: out std_logic);
end Controller;
architecture Behavioral of Controller is
signal state: std_logic_vector(4 downto 0):=(others => '0');
signal gotemp, donetemp, sign, signaccel, goaccel, doneaccel, flag: std_logic:='0';
signal stateconv, stateconv2: std_logic_vector(1 downto 0):=(others => '0');
signal statedisp, statedisp2: std_logic_vector(2 downto 0):=(others => '0');
signal temp_data1: std_logic_vector(7 downto 0):=(others => '0');
signal temp_data2, accel_data1, accel_data2: std_logic_vector(7 downto 0):=(others => '0');
signal value, temperature: std_logic_vector(8 downto 0):=(others => '0');
signal acceleration: std_logic_vector(15 downto 0):=(others => '0');
signal D2, D1, D0, DA3, DA2, DA1, DA0: std_logic_vector(3 downto 0):=(others => '0');
begin
	process begin
	wait until clk'event and clk = '1';
		case state is
when "00000" => if (done = '1') then rw <= '0'; dev_add <= "0011000"; 					N_Byte <= "000010"; 
				R_Pointer <= "00000001"; 
				state <= "00001"; gotemp <= '0'; 
				goaccel <= '0';
					     else gotemp <= '0'; goaccel <= '0'; end if;
			when "00001" => go <= '1'; state <= "00010";
			when "00010" => go <= '0'; state <= "00011";
			when "00011" => if (ready = '1') then dwr <= "00000000"; 
							state <= "00100"; end if;
			when "00100" => state <= "00101";
			when "00101" => if (ready = '1') then dwr <= "00000000"; 
						state <= "00110"; end if;
			when "00110" => state <= "00111";
			when "00111" => if (done = '1') then rw <= '0'; dev_add <= "0011001"; 							N_Byte <= "000001"; R_Pointer <= "00100000";  							state <= "01000"; end if;
			when "01000" => go <= '1'; state <= "01001";
			when "01001" => go <= '0'; state <= "01010";
			when "01010" => if (ready = '1') then dwr <= "00100111"; 
						state <= "01011"; end if;
			when "01011" => state <= "01100";
			when "01100" => if (done = '1' and flag = '0') then rw <= '1'; 
						dev_add <= "0011000"; N_Byte <= "000010";   							R_Pointer <= "00000101"; state <= "01101"; end if;
			when "01101" => go <= '1'; state <= "01110";
			when "01110" => go <= '0'; state <= "01111";
			when "01111" => if (ready = '1') then temp_data1 <= drd; 
						state <= "10000"; end if;
			when "10000" => state <= "10001";
			when "10001" => if (ready = '1') then temp_data2 <= drd; 
						state <= "10010"; end if;
			when "10010" => state <= "10011"; flag <= '1'; gotemp <= '1';
			when "10011" => if (done = '1' and flag = '1') then rw <= '1'; 
						dev_add <= "0011001"; N_Byte <= "000001"; 							R_Pointer <= "00101000"; state <= "10100"; end if;
			when "10100" => go <= '1'; state <= "10101";
			when "10101" => go <= '0'; state <= "10110";
			when "10110" => if (ready = '1') then accel_data1 <= drd; 
						state <= "10111"; end if;
			when "10111" => state <= "11000";
			when "11000" => if (done = '1' and flag = '1') then rw <= '1'; 
						dev_add <= "0011001"; N_Byte <= "000001"; 							R_Pointer <= "00101001"; state <= "11001"; end if;
			when "11001" => go <= '1'; state <= "11010";
			when "11010" => go <= '0'; state <= "11011";
			when "11011" => if (ready = '1') then accel_data2 <= drd; 
						state <= "01100"; goaccel <= '1'; flag <= '0'; end if;
			when others => state <= "01100";
		end case;
	end process;
	temperature <= temp_data1(4 downto 0) & temp_data2(7 downto 4);
	process begin
	wait until clk'event and clk = '1';
	   case stateconv is
			when "00" => if (gotemp = '1') then value <= temperature; 
						stateconv <= "01"; D2 <= "0000"; D1 <= "0000"; 							donetemp <= '0'; end if;
			when "01" => if (value(8) = '1') then sign <= '1'; value <= (not value) + '1'; 						stateconv <= "10";
					else sign <= '0'; stateconv <= "10"; end if;
			when "10" => if (value > "01100011") then value <= value - "01100100"; 								D2 <= D2 + "0001";
					elsif (value > "00001001") then 
						value <= value - "00001010"; D1 <= D1 + "0001";
					else D0 <= value(3 downto 0); stateconv <= "11"; 								donetemp <= '1'; end if;
			when "11" => donetemp <= '0'; stateconv <= "00";
			when others => value <= value; stateconv <= "00";
		end case;
	end process;
	process begin
	wait until clk'event and clk = '1';
	   case stateconv2 is
			when "00" => if (goaccel = '1') then 
						acceleration <= accel_data2&accel_data1; 								stateconv2 <= "01"; DA2 <= "0000"; 
						DA1 <= "0000"; DA3 <= "0000"; doneaccel <= '0'; 					           end if;
			when "01" => if (acceleration(15) = '1') then signaccel <= '1'; 								acceleration <= (not acceleration) + '1'; 
						stateconv2 <= "10";
					else signaccel <= '0'; stateconv2 <= "10"; end if;
			when "10" => if (acceleration > "0000001111100111") then 
					     acceleration <= acceleration - "0000001111101000"; 						     DA3 <= DA3 + "0001";
					elsif (acceleration > "0000000001100011") then 							         acceleration <= acceleration - "0000000001100100"; 						         DA2 <= DA2 + "0001";
elsif (acceleration > "0000000000001001") then                   	acceleration <= acceleration -"0000000000001010"; 
	DA1 <= DA1 + "0001";
					else DA0 <= acceleration(3 downto 0); stateconv2 <= "11"; 						doneaccel <= '1'; end if;
			when "11" => doneaccel <= '0'; stateconv2 <= "00";
			when others => temperature <= temperature; stateconv2 <= "00";
		end case;
	end process;
	process begin
	wait until clk'event and clk = '1';
	if (donetemp = '1') then 
		case statedisp is
			when "000" => if (donetemp = '1') then 
						if (sign = '1') then 
							DIN <= "10110000"; WADD <= "00101"; 
							W <= '1'; statedisp <= "001";
						else DIN <= "00101011"; WADD <= "00101"; 
								W <= '1'; statedisp <= "001"; end if; 
					else W <= '0'; end if;
			when "001" => W <= '1'; WADD <= "00110"; DIN <= "0011"&D2; 						  statedisp <= "010";
			when "010" => W <= '1'; WADD <= "00111"; DIN <= "0011"&D1; 						  statedisp <= "011";
			when "011" => W <= '1'; WADD <= "01000"; DIN <= "0011"&D0; 						  statedisp <= "100";
			when "100" => W <= '1'; WADD <= "01001"; DIN <= "01000011"; 						  statedisp <= "000";
			when others => W <= '0'; statedisp <= "000"; WADD <= "00000";
		end case; 
	elsif (doneaccel = '1') then
		case statedisp2 is
			when "000" => if (doneaccel = '1') then 
						if (signaccel = '1') then DIN <= "10110000"; 									WADD <= "10101"; W <= '1'; 									statedisp2 <= "001";									else DIN <= "00101011"; WADD <= "10101"; 
						        W <= '1'; statedisp2 <= "001"; end if; 
					 else W <= '0'; end if;
			when "001" => W <= '1'; WADD <= "10111"; DIN <= "0011"&DA2; 						  statedisp2 <= "010";
			when "010" => W <= '1'; WADD <= "11000"; DIN <= "0011"&DA1; 						  statedisp2 <= "011";
			when "011" => W <= '1'; WADD <= "11001"; DIN <= "0011"&DA0; 						  statedisp2 <= "100";
			when "100" => W <= '1'; WADD <= "10110"; DIN <= "0011"&DA3; 						  statedisp2 <= "000";
			when others => W <= '0'; statedisp2 <= "000"; WADD <= "00000";
		end case;
	end if;
	end process;
end Behavioral;
