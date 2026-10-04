`default_nettype none
module dds_sincos_lut #(parameter LUT_BITS=12, parameter ROM_FILE="mem/sine_lut.hex")(
 input wire clk, rst, enable, valid_in,
 input wire [LUT_BITS-1:0] sine_addr, cosine_addr,
 input wire sine_negative, cosine_negative, sine_peak, cosine_peak,
 output reg [15:0] sine_magnitude, cosine_magnitude,
 output reg sine_negative_out, cosine_negative_out, sine_peak_out, cosine_peak_out,
 output reg valid_out);
 (* rom_style = "block" *) reg [15:0] rom [0:(1<<LUT_BITS)-1];
 initial $readmemh(ROM_FILE,rom);
 // No reset on memory data registers: preserve synchronous ROM inference.
 always @(posedge clk) if (enable) begin
  sine_magnitude <= rom[sine_addr]; cosine_magnitude <= rom[cosine_addr];
 end
 always @(posedge clk) begin
  if (rst) begin
   sine_negative_out<=0; cosine_negative_out<=0;
   sine_peak_out<=0; cosine_peak_out<=0; valid_out<=0;
  end else if (enable) begin
   sine_negative_out<=sine_negative; cosine_negative_out<=cosine_negative;
   sine_peak_out<=sine_peak; cosine_peak_out<=cosine_peak; valid_out<=valid_in;
  end
 end
endmodule
`default_nettype wire
