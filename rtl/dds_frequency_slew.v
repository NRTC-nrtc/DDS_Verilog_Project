`default_nettype none
module dds_frequency_slew(input wire clk,rst,enable,command_valid,slew_enable,
 input wire [31:0] target_in,step_in,
 output reg [31:0] current, target, step, output reg busy);
 wire [31:0] distance = (target>=current) ? target-current : current-target;
 always @(posedge clk) begin
  if (rst) begin current<=0; target<=0; step<=0; busy<=0; end
  else if (command_valid) begin
   target<=target_in; step<=step_in;
   if (!slew_enable || step_in==32'd0) begin current<=target_in; busy<=0; end
   else busy <= current!=target_in;
  end else if (enable && busy) begin
   if (distance<=step) begin current<=target; busy<=0; end
   else if (target>current) current<=current+step;
   else current<=current-step;
  end
 end
endmodule
`default_nettype wire
