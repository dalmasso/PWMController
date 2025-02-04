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

ENTITY PwmController is

GENERIC(
	sys_clock: INTEGER := 100_000_000;
	pwm_resolution: INTEGER := 8;
	signal_output_freq: INTEGER := 7;
	signal_output_freq_error: INTEGER := 1
);

PORT(
	i_sys_clock: IN STD_LOGIC;
    i_reset: IN STD_LOGIC;
	i_duty_cycle: IN UNSIGNED(pwm_resolution downto 0);
	o_next_duty_cycle_trigger: OUT STD_LOGIC;
	o_pwm: OUT STD_LOGIC
);

END PwmController;

ARCHITECTURE Behavioral of PwmController is

------------------------------------------------------------------------
-- Constant Declarations
------------------------------------------------------------------------
-- System Clock Period
constant SYSTEM_CLOCK_PERIOD: REAL := real(1) / real(sys_clock);

-- PWM Resolution Max Value
constant PWM_RESOLUTION_MAX_VALUE: INTEGER := 2**pwm_resolution;

-- PWM Duty Cycle Frequency
constant PWM_DUTY_CYCLE_FREQUENCY: INTEGER := INTEGER( PWM_RESOLUTION_MAX_VALUE * signal_output_freq);

-- PWM Max Clock Divider
constant PWM_MAX_CLOCK_DIVIDER: INTEGER := INTEGER( real(1) / (real(PWM_RESOLUTION_MAX_VALUE) * SYSTEM_CLOCK_PERIOD * real(PWM_DUTY_CYCLE_FREQUENCY) ) );

------------------------------------------------------------------------
-- Signal Declarations
------------------------------------------------------------------------
-- PWM Clock Divider & Clock Enable
signal pwm_clock_divider: INTEGER range 0 to PWM_MAX_CLOCK_DIVIDER := 0;
signal pwm_clock_enable: STD_LOGIC := '0';

-- PWM Counter
signal pwm_counter: UNSIGNED(pwm_resolution-1 downto 0) := (others => '0');

-- Duty Cycle Input Register
signal duty_cycle_reg: UNSIGNED(pwm_resolution downto 0) := (others => '0');

------------------------------------------------------------------------
-- Module Implementation
------------------------------------------------------------------------
begin

	--------------------------------------------------
	-- PWM Frequency Output Configuration Assertion --
	--------------------------------------------------
	process
	variable duty_cycle: real;
	variable signal_output_freq_min: real;
	variable signal_output_freq_max: real;
	variable signal_output_freq_actual: real;
	begin
		duty_cycle := ( real(1) / ( real(PWM_RESOLUTION_MAX_VALUE) * SYSTEM_CLOCK_PERIOD * (real(PWM_MAX_CLOCK_DIVIDER) + 1.0) ) );
		signal_output_freq_min := real(signal_output_freq) - real(signal_output_freq_error);
		signal_output_freq_max := real(signal_output_freq) + real(signal_output_freq_error);
		signal_output_freq_actual := ( duty_cycle / real(PWM_RESOLUTION_MAX_VALUE) );
		
		assert (signal_output_freq_min <= signal_output_freq_actual) and (signal_output_freq_actual <= signal_output_freq_max)
		report
				"PWM Module Configuration Failure !" & LF &
				"Signal Output Freq Min: " & real'image(real(signal_output_freq_min)) & LF &
				"Signal Output Freq Max: " & real'image(real(signal_output_freq_max)) & LF &
				"Actual Signal Output Freq: " & real'image(real(signal_output_freq_actual))
		severity FAILURE;
		wait;
	end process;

	-----------------------
	-- PWM Clock Divider --
	-----------------------
	process(i_sys_clock)
	begin
		if rising_edge(i_sys_clock) then

			-- Reset PWM Clock Divider
			if (i_reset = '1') or (PWM_MAX_CLOCK_DIVIDER = 0) or (pwm_clock_divider = PWM_MAX_CLOCK_DIVIDER -1) then
				pwm_clock_divider <= 0;

			-- Increment PWM Clock Divider
			else
				pwm_clock_divider <= pwm_clock_divider +1;
			end if;
		end if;
	end process;

	-----------------------
	-- PWM Clock Enable --
	-----------------------
	process(i_sys_clock)
	begin
		if rising_edge(i_sys_clock) then

			-- Reset PWM Clock Enable
			if (i_reset = '1') then
				pwm_clock_enable <= '0';
			
			-- PWM Clock Enable
			elsif (PWM_MAX_CLOCK_DIVIDER = 0) or (pwm_clock_divider = PWM_MAX_CLOCK_DIVIDER -1) then
				pwm_clock_enable <= '1';
			
			-- PWM Clock Disable
			else
				pwm_clock_enable <= '0';
			end if;
		end if;
	end process;

	-----------------
	-- PWM Counter --
	-----------------
	process(i_sys_clock)
	begin
		if rising_edge(i_sys_clock) then

			-- Reset PWM Counter
			if (i_reset = '1') then
				pwm_counter <= (others => '0');
			
			-- PWM Clock Enable
			elsif (pwm_clock_enable = '1') then
				
				-- Increment PWM Counter
				pwm_counter <= pwm_counter + 1;

			end if;
		end if;
	end process;

	------------------------------
	-- Duty Cycle Input Handler --
	------------------------------
	process(i_sys_clock)
	begin
		if rising_edge(i_sys_clock) then
			
			-- Reset or PWM Clock Enable and End of PWM Counter
			if (i_reset = '1') or ((pwm_clock_enable = '1') and (pwm_counter = PWM_RESOLUTION_MAX_VALUE -1)) then
				duty_cycle_reg <= i_duty_cycle;
			end if;

		end if;
	end process;

	-----------------------------
	-- Next Duty Cycle Trigger --
	-----------------------------
	process(i_sys_clock)
	begin
		if rising_edge(i_sys_clock) then
			
			-- PWM Clock Enable and End of PWM Counter
			if (pwm_clock_enable = '1') and (pwm_counter = PWM_RESOLUTION_MAX_VALUE -1) then
				o_next_duty_cycle_trigger <= '1';
			
			else
				o_next_duty_cycle_trigger <= '0';
			end if;

		end if;
	end process;

	----------------
	-- PWM Output --
	----------------
	process(i_sys_clock)
	begin
		if rising_edge(i_sys_clock) then

			-- Reset PWM Output
			if (i_reset = '1') then 
				o_pwm <= '0';
			
			-- PWM Clock Enable
			elsif (pwm_clock_enable = '1') then

				-- Reset PWM Output
				if (pwm_counter >= duty_cycle_reg) then
					o_pwm <= '0';
				
				-- Set PWM Output
				else
					o_pwm <= '1';
				end if;
			end if;

		end if;
	end process;

end Behavioral;