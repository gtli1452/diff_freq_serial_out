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
add wave -HEXADECIMAL sim:/diff_freq_serial_out_tb/serial_out_unit/update_tick
add wave -HEXADECIMAL sim:/diff_freq_serial_out_tb/serial_out_unit/decoder_dut/state_reg
add wave -HEXADECIMAL sim:/diff_freq_serial_out_tb/serial_out_unit/decoder_dut/freq_buf_reg
add wave -HEXADECIMAL sim:/diff_freq_serial_out_tb/serial_out_unit/decoder_dut/freq_num_reg
add wave -HEXADECIMAL sim:/diff_freq_serial_out_tb/serial_out_unit/decoder_dut/pack_num_reg
add wave -HEXADECIMAL sim:/diff_freq_serial_out_tb/serial_out_unit/decoder_dut/cmd_reg

run 4.1ms
wave zoom range 4.01ms 4.025ms
#q
