`default_nettype none
module dds_output_stage(input wire clk, rst, enable, valid_in,
 input wire [15:0] sine_magnitude, cosine_magnitude,
 input wire sine_negative, cosine_negative, sine_peak, cosine_peak,
 output reg signed [15:0] sine_out, cosine_out, output reg out_valid);
 wire signed [15:0] sm = sine_peak ? 16'sd32767 : $signed(sine_magnitude);
 wire signed [15:0] cm = cosine_peak ? 16'sd32767 : $signed(cosine_magnitude);
 always @(posedge clk) begin
  if (rst) begin sine_out<=0; cosine_out<=0; out_valid<=0; end
  else begin
   out_valid <= enable && valid_in;
   if (enable && valid_in) begin
    sine_out <= sine_negative ? -sm : sm;
    cosine_out <= cosine_negative ? -cm : cm;
   end
  end
 end
endmodule
`default_nettype wire
