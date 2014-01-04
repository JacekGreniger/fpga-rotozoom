library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;


entity top is
    port ( 
		-- clock
	 	CLKIN : in std_logic; 

		VGA_HSYNC_OUT : out  STD_LOGIC;
		VGA_VSYNC_OUT : out  STD_LOGIC;
		VGA_R_OUT : out  STD_LOGIC;
		VGA_G_OUT : out  STD_LOGIC;
		VGA_B_OUT : out  STD_LOGIC
	
	);
end top;

architecture Behavioral of top is


signal hsync : std_logic;
signal vsync : std_logic;
signal active_area : std_logic;
signal pixel_color : std_logic;
signal pixel_clock : std_logic;

signal X0 : unsigned(15 downto 0);
signal Y0 : unsigned(15 downto 0);
signal X1 : unsigned(15 downto 0);
signal Y1 : unsigned(15 downto 0);

signal hcounter : integer range 0 to 1023;
signal vcounter : integer range 0 to 1023;

signal C100 : unsigned(15 downto 0) := X"0069";
signal C400 : unsigned(15 downto 0) := X"0190";
constant CSTEP : unsigned(15 downto 0) := X"0005";
signal cnt : integer range 0 to 50000000:= 0;

signal direction : std_logic := '0';

begin

	process (CLKIN) is --50MHz
	begin
		if rising_edge(CLKIN) then
			pixel_clock <= not pixel_clock;
		end if;
	end process;
	
	process (CLKIN) is --50MHz
	begin
		if rising_edge(CLKIN) then
			if cnt > 250000 and vsync='0' then
				if direction = '0' then
					C100 <= C100 + CSTEP;
					C400 <= C400 - CSTEP;
					if C400 <= CSTEP then
						direction <= not direction;
					end if;
				else
					C100 <= C100 - CSTEP;
					C400 <= C400 + CSTEP;
					if C400 > 1000 then
						direction <= not direction;
					end if;
				end if;
				cnt <= 0;
			else
				cnt <= cnt + 1;
			end if;
		end if;
	end process;
	
	process (pixel_clock) is
	begin
		if rising_edge(pixel_clock) then
			if vsync = '0' then
				X0 <= (others=>'0');
				Y0 <= (others=>'0');
				X1 <= (others=>'0');
				Y1 <= (others=>'0');
			elsif hsync = '0' and hcounter=10 then
				X0 <= X1 - C100;
				Y0 <= Y1 + C400;
				X1 <= X1 - C100;
				Y1 <= Y1 + C400;
			elsif active_area='1' then
				X0 <= X0 + C400;
				Y0 <= Y0 + C100;
			end if;
		end if;
	end process;

	pixel_color <= X0(15) xor Y0(15);

	process(pixel_clock)
	begin
		if rising_edge(pixel_clock) then
			if hcounter = 799 then --800 us
				hcounter <= 0;
				if vcounter = 520 then --521 lines
					vcounter <= 0;
				else
					vcounter <= vcounter+1;
				end if;
			else
				hcounter <= hcounter+1;
			end if;
		end if;
	end process;


	process(hcounter, vcounter)
	begin
		hsync <= '1';
		vsync <= '1';
		active_area <= '1';

		if vcounter < (2+29) or vcounter > (2+29+480) or hcounter < (96+48) or hcounter > (96+48+640) then
			active_area <= '0';
		end if;

		if hcounter < 96 then
			hsync <= '0';
		end if;

		if vcounter < 2 then
			vsync <= '0';
		end if;
	end process;

	VGA_HSYNC_OUT <= hsync;
	VGA_VSYNC_OUT<= vsync;
	VGA_R_OUT <= pixel_color when active_area='1' else '0';
	VGA_G_OUT <= pixel_color when active_area='1' else '0';
	VGA_B_OUT <= pixel_color when active_area='1' else '0';

end Behavioral;

