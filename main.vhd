-- FATMA OK
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity main is
	generic(
    clk_freq              : INTEGER := 50_000_000; --system clock frequency in Hz
    debounce_counter_size : INTEGER := 8
	);
   port(
     clk		: in std_logic; --system clock input
	  reset	: in std_logic := '1';
	  pb		: in std_logic := '1';
	  lcd_on	: out std_logic := '1';
	  en		: out std_logic := '0';
	  rs		: out std_logic := '0';
	  rw		: out std_logic := '0';
	  blon   : out std_logic := '0';
	  --	  bf 		: out std_logic := '0';
	  db		: inout std_logic_vector (7 downto 0);
     ps2_clk    : IN  STD_LOGIC;                     --clock signal from PS2 keyboard
     ps2_data   : IN  STD_LOGIC;                     --data signal from PS2 keyboard
	  LEDG		: out std_logic_vector (7 downto 0)
	);  -- inout
end main;

ARCHITECTURE arc OF main IS
  SIGNAL ascii_new  : STD_LOGIC := '0';                     --50MHz/18000 de bir yeni kod sinyali gönderiyor
  SIGNAL ascii_code : STD_LOGIC_VECTOR(6 DOWNTO 0);  --Klavyeden gelen verinin ascii değeri

  -- Klavye için nesne tanımlaması (nesne oluşturulmuyor !)
  COMPONENT ps2_keyboard_to_ascii IS
	  GENERIC(
			clk_freq 					  : INTEGER; --system clock frequency in Hz
			ps2_debounce_counter_size : INTEGER  --set such that 2^size/clk_freq = 5us (size = 8 for 50MHz)
		);        
	  PORT(
			clk        : IN  STD_LOGIC;                     --system clock input
			ps2_clk    : IN  STD_LOGIC;                     --clock signal from PS2 keyboard
			ps2_data   : IN  STD_LOGIC;                     --data signal from PS2 keyboard
			ascii_new  : OUT STD_LOGIC;                     --output flag indicating new ASCII value
			ascii_code : OUT STD_LOGIC_VECTOR(6 DOWNTO 0)   --ASCII value
		); 
	END COMPONENT;
	
	-- lcd için nesne tanımlaması (nesne oluşturulmuyor !)
	component lcd_01 is
	port (
		  clk		: in std_logic;
		  reset	: in std_logic;
		  tick   : in std_logic;
		  data   : in std_logic_vector(6 downto 0);
		  pb		: in std_logic;
		  lcd_on	: out std_logic;
		  blon   : out std_logic;
		  en		: out std_logic;
		  rs		: out std_logic;
		  rw		: out std_logic;
		  db		: inout std_logic_vector (7 downto 0);
		  LEDG	: out std_logic_vector (7 downto 0)
	);
	end component;
	
BEGIN

  -- Klavye nesnesi oluşturuluyor
  keyboard_birimi: ps2_keyboard_to_ascii
    GENERIC MAP(clk_freq => clk_freq, ps2_debounce_counter_size => debounce_counter_size)
    PORT MAP(clk => clk, ps2_clk => ps2_clk, ps2_data => ps2_data, ascii_new => ascii_new, ascii_code => ascii_code);

  lcd_birimi: lcd_01
    PORT MAP(clk => clk, reset => reset, tick => ascii_new, data => ascii_code, pb => pb, lcd_on => lcd_on, en => en, rs => rs, rw => rw, db => db, LEDG => LEDG, blon => blon);



  
END arc;