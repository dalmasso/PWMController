------------------------------------------------------------------------
-- Engineer:    Dalmasso Loic
-- Create Date: 28/01/2025
-- Module Name: PwmController
-- Description:
--      PWM Controller with configurable PWM Resolution (in bits), PWM Signal Output Frequency (Hz) and PWM Signal Output Frequency Error Range (Hz).
--		The size of the Duty Cycle input is 1-bit greater than the PWM Resolution to handle 100% Duty Cycle.
--		The Duty Cyle value is dynamic but the new value will be applied only at the end of the PWM Duty Cycle Period (when Next Duty Cycle Trigger is enable).
--		User MUST carefully select generic parameters to satisfy PWM Output Frequency & Accuracy. Otherwise, assertion will be throw.
--		User can fix a Range of valid PWM Frequency Output.
--
-- Generics
--		sys_clock: System Input Clock Frequency (Hz)
--		pwm_resolution: PWM Resolution (Bits)
--		signal_output_freq: PWM Signal Output Frequency (Hz)
--		signal_output_freq_error: Range of PWM Signal Output Error Range (Hz)
-- Ports
--		Input 	-	i_sys_clock: System Input Clock
--		Input 	-	i_reset: Reset ('0': No Reset, '1': Reset)
--		Input 	-	i_duty_cycle: Duty Cycle to apply (Value Range: [0;2^pwm_resolution])
--		Output 	-	o_next_duty_cycle_trigger: Next Duty Cycle Trigger ('0': No Trigger, '1': Trigger Enable)
--		Output 	-	o_pwm: PWM Output
------------------------------------------------------------------------

LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

ENTITY Testbench_PwmController is
END Testbench_PwmController;

ARCHITECTURE Behavioral of Testbench_PwmController is

COMPONENT PwmController is

GENERIC(
	sys_clock: INTEGER := 100_000_000;
	pwm_resolution: INTEGER := 8;
	signal_output_freq: INTEGER := 20_000;
	signal_output_freq_error: INTEGER := 500
);

PORT(
	i_sys_clock: IN STD_LOGIC;
    i_reset: IN STD_LOGIC;
	i_duty_cycle: IN UNSIGNED(pwm_resolution downto 0);
	o_next_duty_cycle_trigger: OUT STD_LOGIC;
	o_pwm: OUT STD_LOGIC
);
    
END COMPONENT;

signal sys_clock: STD_LOGIC := '0';
signal reset: STD_LOGIC := '0';
signal duty_cycle: unsigned(8 downto 0) := (others => '0');
signal next_duty_cycle_trigger: STD_LOGIC := '0';
signal pwm_out: STD_LOGIC := '0';

begin

-- Clock 100 MHz
sys_clock <= not(sys_clock) after 5 ns;

-- Reset
reset <= '1', '0' after 145 ns;

-- Duty Cycle
duty_cycle <= "000000111", "000000000" after 496 us, "011111111" after 800 us, "100000000" after 1300 us;

uut: PwmController
    GENERIC map(
        sys_clock => 100_000_000,
        pwm_resolution => 8,
        signal_output_freq => 7,
        signal_output_freq_error => 1
    )
    PORT map(
        i_sys_clock => sys_clock,
        i_reset => reset,
        i_duty_cycle=> duty_cycle,
        o_next_duty_cycle_trigger => next_duty_cycle_trigger,
        o_pwm => pwm_out);

end Behavioral;