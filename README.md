# PWM Controller

This module implements a configurable PWM controller. User can set the following parameters:
- System Input Clock: the frequency (Hz) of the PWM module
- PWM Output Frequency: the frequency (Hz) of the PWM Output signal
- PWM Output Frequency Error: the accepted range of the PWM Output Frequency (Hz)
- PWM Resolution: PWM Resolution (bits) of the internal counter

<img width="514" alt="pwm" src="https://github.com/user-attachments/assets/762d4079-8940-455b-aca9-65767e7f0288" />

## Usage

Simply set the PWM parameters (i.e., System Input Clock, PWM Output Frequency, PWM Output Frequency Error and PWM Resolution).

The PWM Controller will automatically verify if the requirements are satisfied (essentially the PWM Output Frequency). If not, an error message will be displayed as shown below:

```
PWM Module Configuration Failure !
PWM Output Freq Min: xxx
PWM Output Freq Max: xxx
PWM Output Freq Actual: xxx
```

## PWM Controller Pin Description

### Generics

| Name | Description |
| ---- | ----------- |
| sys_clock | Frequency (Hz) of the PWM module |
| pwm_output_freq | Frequency (Hz) of the PWM Output signal |
| pwm_output_freq_error | Accepted range of the PWM Output Frequency (Hz) |
| pwm_resolution | PWM Resolution (bits) of the internal counter |

### Ports

| Name | Type | Description |
| ---- | ---- | ----------- |
| i_sys_clock | Input | System Input Clock |
| i_reset | Input | Reset ('0': No Reset, '1': Reset) |
| i_duty_cycle | Input | Duty Cycle to apply (Value Range: [0;2<sup>pwm_resolution</sup>]) |
| o_next_duty_cycle_trigger | Output | Next Duty Cycle Trigger ('0': No Trigger, '1': Trigger Enable) |
| o_pwm | Output | PWM Output |
