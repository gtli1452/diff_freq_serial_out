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
vlog -work diff_freq_serial_out_lib +incdir+$rtl_dir $rtl_dir/pattern_ram.v
vlog -work diff_freq_serial_out_lib +incdir+$rtl_dir $rtl_dir/period_count.v

# ------------------------------------------------------------------- #
# Compiling core
# ------------------------------------------------------------------- #

# ------------------------------------------------------------------- #
# Compiling components of Test Bench
# ------------------------------------------------------------------- #

vlog -work diff_freq_serial_out_lib +incdir+$tb_dir $tb_dir/diff_freq_serial_out_tb.v
vlog -work diff_freq_serial_out_lib +incdir+$tb_dir $tb_dir/decoder_tb.v
vlog -work diff_freq_serial_out_lib +incdir+$tb_dir $tb_dir/altera_mf.v

# ------------------------------------------------------------------- #
# Loading the Test Bench
# ------------------------------------------------------------------- #

vsim -lib diff_freq_serial_out_lib diff_freq_serial_out_tb

# add wave -HEXADECIMAL sim:/diff_freq_serial_out_tb/*
add wave -HEXADECIMAL sim:/diff_freq_serial_out_tb/clk
add wave -HEXADECIMAL sim:/diff_freq_serial_out_tb/serial_out0_o
add wave -HEXADECIMAL sim:/diff_freq_serial_out_tb/serial_out1_o
add wave -HEXADECIMAL sim:/diff_freq_serial_out_tb/serial_out_unit/decode_sel_out
add wave -HEXADECIMAL sim:/diff_freq_serial_out_tb/serial_out_unit/decode_amount
add wave -HEXADECIMAL sim:/diff_freq_serial_out_tb/serial_out_unit/decode_output
add wave -HEXADECIMAL sim:/diff_freq_serial_out_tb/serial_out_unit/decode_addr
add wave -HEXADECIMAL sim:/diff_freq_serial_out_tb/serial_out_unit/channel[0]/entity/ram_wr_i
add wave -HEXADECIMAL sim:/diff_freq_serial_out_tb/serial_out_unit/channel[0]/entity/ram_addr_i
add wave -HEXADECIMAL sim:/diff_freq_serial_out_tb/serial_out_unit/channel[0]/entity/ram_data_i
add wave -HEXADECIMAL sim:/diff_freq_serial_out_tb/serial_out_unit/channel[0]/entity/ram_data_o
add wave -HEXADECIMAL sim:/diff_freq_serial_out_tb/serial_out_unit/channel[0]/entity/bit_index
add wave -HEXADECIMAL sim:/diff_freq_serial_out_tb/serial_out_unit/channel[0]/entity/byte_index
add wave -HEXADECIMAL sim:/diff_freq_serial_out_tb/serial_out_unit/channel[0]/entity/data_bit_reg
add wave -HEXADECIMAL sim:/diff_freq_serial_out_tb/serial_out_unit/channel[0]/entity/state_reg
add wave -HEXADECIMAL sim:/diff_freq_serial_out_tb/serial_out_unit/period_count/*

run 1.02ms
wave zoom range 1.01ms 1.02ms
#q
