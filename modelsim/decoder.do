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

vlog -work diff_freq_serial_out_lib +incdir+$tb_dir $tb_dir/decoder_tb.v

# ------------------------------------------------------------------- #
# Loading the Test Bench
# ------------------------------------------------------------------- #

vsim -lib diff_freq_serial_out_lib decoder_tb

add wave -HEXADECIMAL sim:/decoder_tb/*
add wave -HEXADECIMAL sim:/decoder_tb/decoder_dut/state_reg
add wave -HEXADECIMAL sim:/decoder_tb/decoder_dut/freq_buf_reg
add wave -HEXADECIMAL sim:/decoder_tb/decoder_dut/freq_num_reg
add wave -HEXADECIMAL sim:/decoder_tb/decoder_dut/pack_num_reg
add wave -HEXADECIMAL sim:/decoder_tb/decoder_dut/cmd_reg

run 1.5ms
wave zoom range 0ms 1.5ms
#q
