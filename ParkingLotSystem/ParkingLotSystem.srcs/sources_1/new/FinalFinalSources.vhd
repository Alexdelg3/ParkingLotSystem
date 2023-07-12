library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.std_logic_unsigned.all;
entity Car_Parking_System_VHDL is
port 
(
  clk,reset: in std_logic; -- Clk and reset
  frontSensor, backSensor: in std_logic; --Sensors
  password: in std_logic_vector(3 downto 0); -- Password inputs
  G_LED,R_LED: out std_logic; -- Go and Stop LEDs
  HEX_1, HEX_2: out std_logic_vector(6 downto 0) -- 7-segment Display
);
end Car_Parking_System_VHDL;

architecture Behavioral of Car_Parking_System_VHDL is
-- FSM States
type FSM_States is (IDLE,WAIT_PASS,WRONG_PASS,RIGHT_PASS,STOP);
signal currentState,nextState: FSM_States;
signal counterWait: std_logic_vector(31 downto 0);
signal red_tmp, green_tmp: std_logic;

begin
-- Sequential Circuit
process(clk,reset)
begin
 if(reset='1') then
  currentState <= IDLE;
 elsif(rising_edge(clk)) then
  currentState <= nextState;
 end if;
end process;
-- Combinational Logic
process(currentState,frontSensor,password,backSensor,counterWait)
 begin
 case currentState is 
 when IDLE =>
 if(frontSensor = '1') then -- If the front sensor is on, a car is approaching
  nextState <= WAIT_PASS;-- Wait for password
 else
  nextState <= IDLE;
 end if;
 when WAIT_PASS =>
 if(counterWait <= x"00000003") then
  nextState <= WAIT_PASS;
 else
 if(password = "0110") then
 nextState <= RIGHT_PASS; -- If password is correct, let them in
 else
 nextState <= WRONG_PASS; -- Else, tell them wrong pass by blinking Green LED
 -- Let them input the password again
 end if;
 end if;
 when WRONG_PASS =>
  if(password = "0110") then
 nextState <= RIGHT_PASS;-- If password is correct, let them in
  else
 nextState <= WRONG_PASS;-- Else, they cannot get in until the password is right
  end if;
 when RIGHT_PASS =>
  if(frontSensor='1' and backSensor = '1') then
 nextState <= STOP; 
 -- If the gate is opening for the current car, and the next car comes, stop the next car and input the password
  elsif(backSensor= '1') then
 -- If the current car enters, and no one is next, IDLE
 nextState <= IDLE;
  else
 nextState <= RIGHT_PASS;
  end if;
when STOP =>
  if(password = "0110")then
  -- Checks password of the next car & if correct, open
 nextState <= RIGHT_PASS;
  else
 nextState <= STOP;
  end if;
 when others => nextState <= IDLE;
 end case;
 end process;
process(clk,reset)
 begin
 if(reset='1') then
 counterWait <= (others => '0');
 elsif(rising_edge(clk))then
  if(currentState=WAIT_PASS)then
  counterWait <= counterWait + x"00000001";
  else 
  counterWait <= (others => '0');
  end if;
 end if;
 end process;
 -- Output 
 process(clk) -- Edits the LED blinking period
 begin
 if(rising_edge(clk)) then
 case(currentState) is
 when IDLE => 
 green_tmp <= '0';
 red_tmp <= '0';
 HEX_1 <= "1111111"; -- Off
 HEX_2 <= "1111111"; -- Off
 when WAIT_PASS =>
 green_tmp <= '0';
 red_tmp <= '1'; 
 -- RED LED turn on and Display 7-segment LED as EN to let the car know they need to input password
 HEX_1 <= "0000110"; -- E 
 HEX_2 <= "0101011"; -- n 
 when WRONG_PASS =>
 green_tmp <= '0'; -- If password is wrong, light the RED LED  
 red_tmp <= not red_tmp;
 HEX_1 <= "0000110"; -- E
 HEX_2 <= "0000110"; -- E 
 when RIGHT_PASS =>
 green_tmp <= not green_tmp;
 red_tmp <= '0'; -- If password is correct, light the GREEN LED
 HEX_1 <= "0000010"; -- G
 HEX_2 <= "1000000"; -- 0 
 when STOP =>
 green_tmp <= '0';
 red_tmp <= not red_tmp; -- Stop the next car and light the RED LED
 HEX_1 <= "0010010"; -- S
 HEX_2 <= "0001100"; -- P 
 when others => 
 green_tmp <= '0';
 red_tmp <= '0';
 HEX_1 <= "1111111"; -- Off
 HEX_2 <= "1111111"; -- Off
  end case;
 end if;
 end process;
  R_LED <= red_tmp  ;
  G_LED <= green_tmp;

end Behavioral;