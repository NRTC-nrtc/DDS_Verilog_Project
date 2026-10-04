`default_nettype none
module dds_phase_mapper #(parameter LUT_BITS=12)(
 input wire clk, rst, enable, valid_in,
 input wire [31:0] phase_in,
 output reg [LUT_BITS-1:0] sine_addr, cosine_addr,
 output reg sine_negative, cosine_negative, sine_peak, cosine_peak,
 output reg valid_out);
 wire [LUT_BITS+1:0] s = phase_in[31:30-LUT_BITS];
 wire [LUT_BITS+1:0] c = s + {2'b01,{LUT_BITS{1'b0}}};
 wire [LUT_BITS-1:0] sf=s[LUT_BITS-1:0], cf=c[LUT_BITS-1:0];
 always @(posedge clk) begin
  if (rst) begin
   sine_addr<=0; cosine_addr<=0; sine_negative<=0; cosine_negative<=0;
   sine_peak<=0; cosine_peak<=0; valid_out<=0;
  end else if (enable) begin
   sine_addr <= s[LUT_BITS] ? (~sf + {{(LUT_BITS-1){1'b0}},1'b1}) : sf;
   cosine_addr <= c[LUT_BITS] ? (~cf + {{(LUT_BITS-1){1'b0}},1'b1}) : cf;
   sine_peak <= s[LUT_BITS] && (sf == {LUT_BITS{1'b0}});
   cosine_peak <= c[LUT_BITS] && (cf == {LUT_BITS{1'b0}});
   sine_negative <= s[LUT_BITS+1]; cosine_negative <= c[LUT_BITS+1];
   valid_out <= valid_in;
  end
 end
endmodule
`default_nettype wire
