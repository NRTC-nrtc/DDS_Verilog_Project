`default_nettype none
module dds_top_advanced #(parameter LUT_BITS=12, parameter ROM_FILE="mem/sine_lut.hex")(
 input wire clk,rst,enable,
 input wire [31:0] fcw_in, input wire fcw_valid,
 input wire [31:0] phase_offset_in, input wire phase_valid,
 input wire frequency_slew_enable, input wire [31:0] frequency_slew_step,
 input wire phase_slew_enable, input wire [31:0] phase_slew_step,
 output wire signed [15:0] sine_out,cosine_out, output wire out_valid,
 output wire frequency_busy,phase_busy);
 wire [31:0] active_fcw, phase_offset,ft,fs,pt,ps;
 dds_frequency_slew frequency_control(clk,rst,enable,fcw_valid,frequency_slew_enable,fcw_in,frequency_slew_step,active_fcw,ft,fs,frequency_busy);
 dds_phase_slew phase_control(clk,rst,enable,phase_valid,phase_slew_enable,phase_offset_in,phase_slew_step,phase_offset,pt,ps,phase_busy);
 dds_engine #(LUT_BITS,ROM_FILE) engine(clk,rst,enable,active_fcw,phase_offset,sine_out,cosine_out,out_valid);
endmodule
`default_nettype wire
