library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
entity i2cmaster is
	port(go, rw, clk, reset: in std_logic;
		  N_Byte: in std_logic_vector(5 downto 0);
		  dev_add: in std_logic_vector(6 downto 0);
		  dwr, R_Pointer: in std_logic_vector(7 downto 0);
		  drd: out std_logic_vector(7 downto 0);
		  done, ready, ack_e: out std_logic;
		  scl, sda: inout std_logic);
end i2cmaster;
architecture Behavioral of i2cmaster is
type state_type is(waiting, start, d_add, sack1, wr_rp, sack2, sr, d_add1, sack3, wr, sack, stop, rd, mack);
signal state: state_type;
signal scl_int, sda_int, R_W, rbit, wbit, ne, pe, stretch, Q3: std_logic;
signal RTX, R, RRX: std_logic_vector(7 downto 0);
signal NB: std_logic_vector(5 downto 0);
signal bc: natural range 0 to 8;
signal count: std_logic_vector(9 downto 0);
begin
	process(clk) begin
		if (clk'event and clk = '1') then
		if (reset = '1') then 
			scl_int <= '1'; sda_int <= '1'; drd <= (others => '0'); 
			done <= '1'; ack_e <= '0'; state <= waiting; 
		end if; 
		case state is
			when waiting => if (go = '1' and sda = '1' and scl = '1') then
						RTX <= R_Pointer; R <= dev_add&'0'; NB <= N_Byte; 
						R_W <= rw; ack_e <= '0'; done <= '0'; state <= start; 
					else scl_int <= '1'; sda_int <= '1'; 
					end if;
			when start =>   if (rbit = '1') then sda_int <= '0';
					elsif (ne = '1' and sda = '0') then scl_int <= '0'; bc <= 8; 								state <= d_add; end if;
			when d_add => if (wbit = '1') then 
						if (bc > 0) then sda_int <= R(bc-1); bc <= bc - 1; 								end if;
					 elsif (pe = '1') then scl_int <= '1'; 
					 elsif (ne = '1') then 
							if (bc = 0) then scl_int <= '0'; sda_int <= '1'; 									state <= sack1; 
							else scl_int <= '0'; end if; end if;
			when sack1 => if (pe = '1') then scl_int <= '1'; 
					 elsif (rbit = '1') then 
						if (sda /= '0') then ack_e <= '1'; 
						else ack_e <= '0'; end if;
elsif (ne = '1') then scl_int <= '0'; sda_int <= '1'; bc <= 8; 			state <= wr_rp; end if;
			when wr_rp => if (wbit = '1') then 
if (bc > 0) then sda_int <= RTX(bc-1); bc <= bc - 1; end if;
					  elsif (pe = '1') then scl_int <= '1';
					  elsif (ne = '1') then 
						if (bc = 0) then scl_int <= '0'; sda_int <= '1';
 state <= sack2;
						else scl_int <= '0'; end if; end if;
			when sack2 => if (pe = '1') then scl_int <= '1';
						elsif (rbit = '1') then 
							if (sda /= '0') then ack_e <= '1'; 
							else ack_e <= '0'; end if;
						elsif (ne = '1') then 
							if (R_W = '1') then scl_int <= '0'; 
								sda_int <= '1'; bc <= 8; state <= sr;
else scl_int <= '0'; sda_int <= '1'; bc <= 8; 				RTX <= dwr; state <= wr; end if;
							 end if;
			when sr =>     if (wbit = '1') then scl_int <= '1';
					elsif (rbit = '1') then sda_int <= '0';
					elsif (ne = '1' and sda = '0') then scl_int <= '0'; bc <= 8; 
						R <= dev_add&'1';  state <= d_add1; end if;
			when d_add1=> if (wbit = '1') then 
						if (bc > 0) then sda_int <= R(bc-1); bc <= bc - 1; 							end if;
					   elsif (pe = '1') then scl_int <= '1';
					   elsif (ne = '1') then 
						if (bc = 0) then scl_int <= '0'; sda_int <= '1'; 
							state <= sack3;
						else scl_int <= '0'; end if; end if;
			when sack3 => if (pe = '1') then scl_int <= '1'; 
					 elsif (rbit = '1') then 
						if (sda /= '0') then ack_e <= '1'; 
						else ack_e <= '0'; end if;
					  elsif (ne = '1') then scl_int <= '0'; sda_int <= '1'; bc <= 8; 							state <= rd; end if;
			when wr =>    if (wbit = '1') then 
						if (bc > 0) then sda_int <= RTX(bc-1); bc <= bc - 1; 						end if;
					elsif (pe = '1') then scl_int <= '1';
					elsif (ne = '1') then 
						if (bc = 0) then scl_int <= '0'; sda_int <= '1'; 
							NB <= NB - '1'; state <= sack;
						else scl_int <= '0'; end if; end if;
			when sack =>  if (pe = '1') then scl_int <= '1';
					elsif (rbit = '1') then 
						if (sda /= '0') then ack_e <= '1'; 
						else ack_e <= '0'; end if;
					elsif (ne = '1') then 
						if (NB > "000000") then 
						scl_int <= '0'; sda_int <= '1'; bc <= 8; RTX <= dwr; 							state <= wr;
						else scl_int <= '0'; sda_int <= '0'; state <= stop; 
						end if; end if;
			when stop =>  if (pe = '1') then scl_int <= '1';
					elsif (rbit = '1') then sda_int <= '1';
					elsif (ne = '1') then scl_int <= '1'; sda_int <= '1'; 
						drd <= (others => '0'); ack_e <= '0'; done <= '1'; 							state <= waiting; end if;
			when rd =>     if (pe = '1') then scl_int <= '1';
				 	elsif (rbit = '1') then 
						if (bc > 0) then RRX(bc-1) <= sda; bc <= bc - 1; 							end if;
					elsif (ne = '1') then 
						if (bc = 0) then scl_int <= '0'; drd <= RRX; 
		NB <= NB -'1'; RRX <= (others => '0'); 				state <= mack;
						else scl_int <= '0'; end if; end if;
			when mack =>  if (wbit = '1') then 
						if (NB > "000000") then sda_int <= '0'; 
						else sda_int <= '1'; end if;
					  elsif (pe = '1') then scl_int <= '1';
					  elsif (ne = '1') then 
if (NB > "000000") then scl_int <= '0'; bc <= 8; 	sda_int <= '1'; state <= rd;
						else scl_int <= '0'; bc <= 8; sda_int <= '0'; 
							state <= stop; end if; end if; end case; end if;
	end process;
	process(clk) begin
		if (clk'event and clk = '1') then
			if (reset = '1') then stretch <= '0'; Q3 <= '0'; end if;
			if (pe = '1') then Q3 <= '1';
			elsif (rbit = '1') then Q3 <= '0';
			elsif (Q3 = '1') then if (scl = '1') then stretch <= '0'; else stretch <= '1'; end if; end if; end if;
	end process;
	process(clk) begin
		if (clk'event and clk = '1') then
			if (reset = '1') then count <= (others => '0'); end if;
			if (state = waiting) then count <= (others => '0');
			elsif (stretch = '0') then count <= count + 1; end if; end if;
	end process;
	process(sda_int) begin
		case sda_int is
			when '1' => sda <= 'Z';
			when '0' => sda <= '0';
			when others => sda <= sda;
		end case;
	end process;
	process(scl_int) begin
		case scl_int is
			when '1' => scl <= 'Z';
			when '0' => scl <= '0';
			when others => scl <= scl;
		end case;
	end process;
	process(state, R_W, NB) begin
		if (wbit = '1') then
		if (state = sack2 and R_W = '0') then ready <= '1';
		elsif (state = sack and NB > "000000") then ready <= '1';
		elsif (state = mack) then ready <= '1';
		else ready <= '0'; end if;
		else ready <= '0'; end if;
	end process;
	process(count) begin
		if (count(7 downto 0) = "0000000") then 
			case count(9 downto 8) is
				when "00" => ne <= '1'; wbit <= '0'; pe <= '0'; rbit <= '0';
				when "01" => ne <= '0'; wbit <= '1'; pe <= '0'; rbit <= '0';
				when "10" => ne <= '0'; wbit <= '0'; pe <= '1'; rbit <= '0';
				when "11" => ne <= '0'; wbit <= '0'; pe <= '0'; rbit <= '1';
				when others => ne <= '0'; wbit <= '0'; pe <= '0'; rbit <= '0';
			end case;
		else ne <= '0'; wbit <= '0'; pe <= '0'; rbit <= '0'; end if;
	end process;
end Behavioral;
