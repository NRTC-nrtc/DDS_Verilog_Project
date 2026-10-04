`default_nettype none
module dds_top #(parameter LUT_BITS=12, parameter ROM_FILE="mem/sine_lut.hex")(
 input wire clk, rst, enable,
 input wire [31:0] fcw_in, input wire fcw_valid,
 input wire [31:0] phase_offset_in, input wire phase_valid,
 output wire signed [15:0] sine_out, cosine_out, output wire out_valid);
 reg [31:0] active_fcw, phase_offset;
 always @(posedge clk) begin
  if (rst) begin active_fcw<=0; phase_offset<=0; end
  else begin
   if (fcw_valid) active_fcw<=fcw_in;
   if (phase_valid) phase_offset<=phase_offset_in;
  end
 end
 dds_engine #(LUT_BITS,ROM_FILE) engine(clk,rst,enable,active_fcw,phase_offset,sine_out,cosine_out,out_valid);
endmodule
`default_nettype wire
