library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity lcd_01 is
port (
	  clk		: in std_logic;
	  reset	: in std_logic := '1';
	  tick   : in std_logic;
	  data   : in std_logic_vector(6 downto 0);
	  pb		: in std_logic := '1';
	  lcd_on	: out std_logic := '1';
	  blon   : out std_logic := '0';
	  en		: out std_logic := '0';
	  rs		: out std_logic := '0';
	  rw		: out std_logic := '0';
--	  bf 		: out std_logic := '0';
	  db		: inout std_logic_vector (7 downto 0); -- inout
	  LEDG	: out std_logic_vector (7 downto 0)
	  
      );  
end lcd_01;

architecture arch of lcd_01 is
	type state_type is (init, disp_on, wr_ddram, clr_disp, en_h, chk_bf, home);
	signal state, next_state : state_type;
	constant delay_15ms 	 : integer := 750000;  -- 750000
	constant delay_4ms 		 : integer := 205000;  -- 205000
	constant delay_100us 	 : integer := 5000;  -- 5000
	constant delay_40ns 	 : integer := 1;  -- 1
	constant delay_240ns 	 : integer := 12; -- 12
	constant delay_500ns 	 : integer := 100; -- 24 (100?)
	signal delay_count  	 : unsigned(19 downto 0);
	signal init_cmd 		 : unsigned(2 downto 0);
	signal rewrite_cmd    : unsigned(2 downto 0);
	SUBTYPE ascii IS STD_LOGIC_VECTOR(7 DOWNTO 0);
	TYPE charArray IS array(1 to 16) OF ascii;
	signal line1: charArray := (x"20",x"46",x"41",x"54",x"4D",x"41",x"20",x"4F",x"4B",x"20",x"20",x"20",x"20",x"20",x"20",x"20");
	signal count 			 : integer := 0; --  unsigned(3 downto 0) := "0001";
	signal line1_count 	 : integer := 0; --  unsigned(3 downto 0) := "0001";
	signal check_bf_f		 : std_logic;
	signal rw_reg			 : std_logic;
	signal db_in, db_out	 : std_logic_vector (7 downto 0);
	
	-- Sonradan eklediklerim
	signal counter: integer := 0; -- Lcd satır 1 sayacı her yeni ascii kodunda bir sonrakisine geçecek
	signal tick_reg : std_logic;
	signal tick_old : std_logic;
	signal first_change : std_logic := '1';
	signal data_reg : std_logic_vector(7 downto 0);
	signal change_tick :  std_logic := '0';
	
begin

--================================================
-- outputs
--================================================
lcd_on <= '1';
rw <= rw_reg;
db <= db_out when rw_reg = '0' else (others => 'Z');  -- write: rw ='0', read: rw = '1' 
db_in <= db;


--================================================
-- SONRADAN EKLEDİM : HARF KONTROLU
--================================================
tick_reg <= tick;
data_reg <= '0'&data;



	   
process (clk, reset, tick_reg, delay_count, init_cmd, rewrite_cmd, state, check_bf_f, db_in)
begin
	if reset = '0' then
		delay_count <= (others => '0');
		init_cmd <= (others => '0');
		rewrite_cmd <= (others => '0');
		count <= 0;
		line1_count <= 0;
		db_out <= (others => '0');
		en <= '0';
		rs <= '0';
		rw_reg <= '0';
		state <= init;
		next_state <= init;	
	elsif clk'event and clk = '1' then
		delay_count <= delay_count + 1;
		en <= '0';
		case state is
--================================================
-- power up
--================================================
			when init =>
				check_bf_f <= '0';
				rs <= '0';
				rw_reg <= '0';
				blon <= '1';
				if (delay_count = delay_15ms and init_cmd = "000") then  -- delay_15ms --4
					delay_count <= (others => '0');
					check_bf_f <= '1';
					init_cmd <= init_cmd + 1;
					db_out <= x"38";
					state <= en_h;
					next_state <= init;
					tick_old <= '0';
				elsif (delay_count = delay_4ms and init_cmd = "001") then  -- delay_4ms -- 2
					delay_count <= (others => '0');
					check_bf_f <= '1';
					init_cmd <= init_cmd + 1;
					db_out <= x"38";
					state <= en_h;
					next_state <= init;
				elsif (delay_count = delay_100us and init_cmd = "010") then  -- delay_100us -- 1
					delay_count <= (others => '0');
					check_bf_f <= '1';
					init_cmd <= init_cmd + 1;
					db_out <= x"38";
					state <= en_h;
					next_state <= init;
				elsif (init_cmd = "011") then		-- start checking busy flag
					delay_count <= (others => '0');
					init_cmd <= init_cmd + 1;
					db_out <= x"38";
					state <= en_h;
					next_state <= init;
				elsif (init_cmd = "100") then  -- DISP OFF
					delay_count <= (others => '0');
					init_cmd <= init_cmd + 1;
					db_out <= x"08";
					state <= en_h;
					next_state <= init;
				elsif (init_cmd = "101") then  -- DISP CLEAR (can take > 1s to execute)
					delay_count <= (others => '0');
					init_cmd <= init_cmd + 1;
					db_out <= x"01";
					state <= en_h;
					next_state <= init;
				elsif (init_cmd = "110") then   -- ENT_MODE_SET
					init_cmd <= (others => '0');
					delay_count <= (others => '0');
					db_out <= x"06";
					state <= en_h;
					next_state <= disp_on; -- disp_on
				end if;
--================================================
-- commands
--================================================
			when disp_on =>
				delay_count <= (others => '0');
				rs <= '0';
				rw_reg <= '0';
				db_out <= x"0F";
				state <= en_h;
				next_state <= wr_ddram;
				
			when wr_ddram =>				-- unintended muxes instantiated?
				delay_count <= (others => '0');
				rs <= '1';
				rw_reg <= '0';
				count <= count + 1;
				if (count <= 15) then
					db_out <= line1(count);
					state <= en_h;
					next_state <= wr_ddram;
				else
					count <= 0;
					state <= home;
					next_state <= home;
				end if;	
				LEDG(5)<='0';
				
				
			when clr_disp =>
				delay_count <= (others => '0');
				db_out <= x"01";  -- clr disp ~1.58ms, can take > 1s to execute
				rs <= '0';
				rw_reg <= '0';
				state <= en_h;
				next_state <= home;
				
			when home =>
				
					if tick_reg = '1' then
					if rewrite_cmd = "000" then
						if (tick_old/=tick_reg) and (tick_reg='1') then
							if first_change = '1' then
								first_change <= '0';
							else
								state <= clr_disp;
								next_state <= home; 
								rewrite_cmd <= rewrite_cmd + 1;
							end if;
						elsif (pb = '1') then
							state <= home;
							next_state <= home; 
						end if;
					elsif rewrite_cmd = "001" then

							line1_count <= line1_count + 1;
							if line1_count=16 then
								line1_count <= 0;
							end if;
							line1(line1_count) <= data_reg;
							rewrite_cmd <= rewrite_cmd + 1;
							-- rewrite_cmd <= (others => '0');
						--change_tick <= '0';
					elsif rewrite_cmd = "010" then
						delay_count <= (others => '0');	
						state <= en_h;
						next_state <= wr_ddram; 
						rewrite_cmd <= (others => '0');
						
					end if;
					
				
				end if;
				
				if (pb = '0') then
					state <= clr_disp;
					next_state <= home; 
				end if;
				tick_old <= tick_reg;
					
--================================================
-- enable controller
--================================================
			when en_h =>
				if delay_count < delay_500ns then  -- N = 25 (~500ns period) or (maybe 24)
					if (delay_count >= delay_40ns and delay_count <= delay_240ns) then	
						en <= '1';
						if delay_count = delay_240ns-1 and rw_reg = '1' then
							if db_in(7) = '0' then
								check_bf_f <= '1';	
							else 
								check_bf_f <= '0';
							end if;
						end if;
					end if;
				else
					delay_count <= (others => '0');
					if check_bf_f = '1' then
						check_bf_f <= '0';
						rw_reg <= '0';
						state <= next_state;
					else
						state <= chk_bf;
					end if;
				end if;
				
--================================================
-- check busy flag
--================================================
			when chk_bf =>
				delay_count <= (others => '0');
				rs <= '0';
				rw_reg <= '1';
				state <= en_h;
		end case;
	end if;
end process;
end arch;