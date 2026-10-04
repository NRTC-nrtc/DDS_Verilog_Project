`default_nettype none
module dds_phase_accumulator(input wire clk, rst, enable,
 input wire [31:0] fcw, output reg [31:0] phase_acc);
 always @(posedge clk) begin
  if (rst) phase_acc <= 32'd0;
  else if (enable) phase_acc <= phase_acc + fcw;
 end
endmodule
`default_nettype wire
