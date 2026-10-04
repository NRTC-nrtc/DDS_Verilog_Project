`default_nettype none
module dds_engine #(parameter LUT_BITS=12, parameter ROM_FILE="mem/sine_lut.hex")(
 input wire clk, rst, enable, input wire [31:0] fcw, phase_offset,
 output wire signed [15:0] sine_out, cosine_out, output wire out_valid);
 wire [31:0] phase_acc;
 reg [31:0] sample_phase;
 reg sample_valid;
 wire [LUT_BITS-1:0] sa,ca;
 wire sn,cn,sp,cp,mv;
 wire [15:0] sm,cm;
 wire rn,rc,rsp,rcp,rv;
 dds_phase_accumulator accumulator(clk,rst,enable,fcw,phase_acc);
 always @(posedge clk) begin
  if (rst) begin sample_phase<=0; sample_valid<=0; end
  else if (enable) begin sample_phase<=phase_acc+phase_offset; sample_valid<=1'b1; end
 end
 dds_phase_mapper #(LUT_BITS) mapper(clk,rst,enable,sample_valid,sample_phase,sa,ca,sn,cn,sp,cp,mv);
 dds_sincos_lut #(LUT_BITS,ROM_FILE) lut(clk,rst,enable,mv,sa,ca,sn,cn,sp,cp,sm,cm,rn,rc,rsp,rcp,rv);
 dds_output_stage output_stage(clk,rst,enable,rv,sm,cm,rn,rc,rsp,rcp,sine_out,cosine_out,out_valid);
endmodule
`default_nettype wire
