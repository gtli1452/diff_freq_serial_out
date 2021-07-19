# ------------------------------------------------------------------- #
# Directories location
# ------------------------------------------------------------------- #

set rtl_dir ./../rtl
set tb_dir  ./../tb

# ------------------------------------------------------------------- #
# Mapping destination directory for models
# ------------------------------------------------------------------- #

vlib work
vmap diff_freq_serial_out_lib work

# ------------------------------------------------------------------- #
# Compiling components of core
# ------------------------------------------------------------------- #

vlog -work diff_freq_serial_out_lib +incdir+$rtl_dir $rtl_dir/mod_m_counter.v
vlog -work diff_freq_serial_out_lib +incdir+$rtl_dir $rtl_dir/uart_tx.v
vlog -work diff_freq_serial_out_lib +incdir+$rtl_dir $rtl_dir/uart_rx.v
vlog -work diff_freq_serial_out_lib +incdir+$rtl_dir $rtl_dir/uart.v
vlog -work diff_freq_serial_out_lib +incdir+$rtl_dir $rtl_dir/serial_out.v
vlog -work diff_freq_serial_out_lib +incdir+$rtl_dir $rtl_dir/diff_freq_serial_out.v
vlog -work diff_freq_serial_out_lib +incdir+$rtl_dir $rtl_dir/decoder.v

# ------------------------------------------------------------------- #
# Compiling core
# ------------------------------------------------------------------- #

# ------------------------------------------------------------------- #
# Compiling components of Test Bench
# ------------------------------------------------------------------- #

vlog -work diff_freq_serial_out_lib +incdir+$tb_dir $tb_dir/diff_freq_serial_out_tb.v
vlog -work diff_freq_serial_out_lib +incdir+$tb_dir $tb_dir/decoder_tb.v

# ------------------------------------------------------------------- #
# Loading the Test Bench
# ------------------------------------------------------------------- #

vsim -lib diff_freq_serial_out_lib diff_freq_serial_out_tb

add wave -HEXADECIMAL sim:/diff_freq_serial_out_tb/*
add wave -HEXADECIMAL sim:/diff_freq_serial_out_tb/serial_out_unit/decode_done_tick
add wave -HEXADECIMAL sim:/diff_freq_serial_out_tb/serial_out_unit/state_reg
add wave -HEXADECIMAL sim:/diff_freq_serial_out_tb/serial_out_unit/decode_cmd
add wave -HEXADECIMAL sim:/diff_freq_serial_out_tb/serial_out_unit/sel_out_reg
add wave -HEXADECIMAL sim:/diff_freq_serial_out_tb/serial_out_unit/output_reg
add wave -HEXADECIMAL sim:/diff_freq_serial_out_tb/serial_out_unit/freq_reg
add wave -HEXADECIMAL sim:/diff_freq_serial_out_tb/serial_out_unit/decode_enable
add wave -HEXADECIMAL sim:/diff_freq_serial_out_tb/serial_out_unit/slow_period_reg
add wave -HEXADECIMAL sim:/diff_freq_serial_out_tb/serial_out_unit/fast_period_reg
add wave -HEXADECIMAL sim:/diff_freq_serial_out_tb/serial_out_unit/update_tick
add wave -HEXADECIMAL sim:/diff_freq_serial_out_tb/serial_out_unit/channel_amount
add wave -HEXADECIMAL sim:/diff_freq_serial_out_tb/serial_out_unit/channel_output

run 6.788ms
wave zoom range 6.783ms 6.788ms
#q
