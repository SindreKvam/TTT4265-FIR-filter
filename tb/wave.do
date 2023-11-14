onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -expand -group FIR /top_tb/FIR_DUT/FIR_LENGTH
add wave -noupdate -expand -group FIR /top_tb/FIR_DUT/clk
add wave -noupdate -expand -group FIR /top_tb/FIR_DUT/rst_n
add wave -noupdate -expand -group FIR /top_tb/FIR_DUT/prev_ready
add wave -noupdate -expand -group FIR /top_tb/FIR_DUT/prev_valid
add wave -noupdate -expand -group FIR /top_tb/FIR_DUT/data_in
add wave -noupdate -expand -group FIR /top_tb/FIR_DUT/next_ready
add wave -noupdate -expand -group FIR /top_tb/FIR_DUT/next_valid
add wave -noupdate -expand -group FIR /top_tb/FIR_DUT/data_out
add wave -noupdate -expand -group FIR /top_tb/FIR_DUT/state
add wave -noupdate -expand -group FIR /top_tb/FIR_DUT/delay_line
add wave -noupdate -expand -group FIR /top_tb/FIR_DUT/coeff
add wave -noupdate -expand -group FIR /top_tb/FIR_DUT/accumulator
add wave -noupdate -expand -group FIR /top_tb/FIR_DUT/sfixed_data_in
add wave -noupdate -expand -group FIR /top_tb/FIR_DUT/tap_counter
add wave -noupdate -expand -group LFSR /top_tb/LFSR_DUT/POLY
add wave -noupdate -expand -group LFSR /top_tb/LFSR_DUT/SEED
add wave -noupdate -expand -group LFSR /top_tb/LFSR_DUT/clk
add wave -noupdate -expand -group LFSR /top_tb/LFSR_DUT/rst_n
add wave -noupdate -expand -group LFSR /top_tb/LFSR_DUT/ready
add wave -noupdate -expand -group LFSR /top_tb/LFSR_DUT/valid
add wave -noupdate -expand -group LFSR /top_tb/LFSR_DUT/data
add wave -noupdate -expand -group LFSR /top_tb/LFSR_DUT/raw_data
add wave -noupdate -expand -group LFSR /top_tb/LFSR_DUT/r_lfsr
add wave -noupdate -expand -group LFSR /top_tb/LFSR_DUT/w_mask
add wave -noupdate -expand -group LFSR /top_tb/LFSR_DUT/w_poly
add wave -noupdate -expand -group LFSR /top_tb/LFSR_DUT/state
add wave -noupdate -expand -group FIFO /top_tb/FIFO_DUT/clk
add wave -noupdate -expand -group FIFO /top_tb/FIFO_DUT/rst_n
add wave -noupdate -expand -group FIFO /top_tb/FIFO_DUT/data
add wave -noupdate -expand -group FIFO /top_tb/FIFO_DUT/valid
add wave -noupdate -expand -group FIFO /top_tb/FIFO_DUT/ready
add wave -noupdate -expand -group FIFO /top_tb/FIFO_DUT/data_counter
add wave -noupdate -expand -group FIFO /top_tb/FIFO_DUT/counter_8k
add wave -noupdate -expand -group FIFO /top_tb/FIFO_DUT/CLK_PERIODS_FOR_8K
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {2373 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 150
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 0
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ns
update
WaveRestoreZoom {0 ps} {28701 ps}
