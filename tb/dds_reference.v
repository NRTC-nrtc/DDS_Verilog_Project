`timescale 1ns/1ps
module dds_reference #(parameter ADVANCED=0)(
 input wire clk,rst,enable, input wire [31:0] fcw_in,phase_offset_in,
 input wire fcw_valid,phase_valid,frequency_slew_enable,phase_slew_enable,
 input wire [31:0] frequency_slew_step,phase_slew_step,
 input wire signed [15:0] sine_out,cosine_out, input wire out_valid,
 input wire [31:0] observed_acc,observed_fcw,observed_offset,
 input wire frequency_busy,phase_busy);
 reg [31:0] acc=0,fcw=0,offset=0,ft=0,pt=0,fs=0,ps=0;
 reg fb=0,pb=0;
 reg [31:0] queue[0:2];
 reg [2:0] valid=0;
 reg [31:0] effective;
 integer expected_s=0,expected_c=0;
 reg expected_valid=0;
 integer cycles=0,checked=0,accepted=0,discarded=0,fcw_changes=0,phase_changes=0,resets=0,stalls=0;
 integer i, pending;
 real distance, delta;
 // Independent full-cycle trigonometric reference; no DUT ROM or mapper reuse.
 function integer wave;
  input [31:0] phase;
  integer index;
  real x;
  begin
   index=phase[31:18];
   x=32767.0*$sin(6.2831853071795864769*index/16384.0);
   if(x>=0.0) wave=$rtoi(x+0.5); else wave=$rtoi(x-0.5);
  end
 endfunction
 task fail;
  begin
   $display("FAIL mode=%0d time=%0t cycle=%0d FCW=%h ACC=%h OFFSET=%h expected sine=%0d actual=%0d cosine=%0d actual=%0d valid=%b actual=%b",ADVANCED,$time,cycles,fcw,acc,offset,expected_s,sine_out,expected_c,cosine_out,expected_valid,out_valid);
   $fatal(1,"Reference mismatch");
  end
 endtask
 always @(posedge clk) begin
  cycles=cycles+1;
  if(rst) begin
   pending=0; for(i=0;i<3;i=i+1) if(valid[i]) pending=pending+1;
   discarded=discarded+pending;
   acc=0; fcw=0; offset=0; ft=0; pt=0; fs=0; ps=0; fb=0; pb=0;
   valid=0; expected_s=0; expected_c=0; expected_valid=0; resets=resets+1;
  end else begin
   expected_valid=0;
   if(enable) begin
    expected_valid=valid[2];
    if(valid[2]) begin
     expected_s=wave(queue[2]); expected_c=wave(queue[2]+32'h40000000);
     checked=checked+1;
    end
    queue[2]=queue[1]; queue[1]=queue[0];
    effective=acc+offset; queue[0]=effective;
    valid={valid[1:0],1'b1}; accepted=accepted+1;
    acc=acc+fcw;
   end else stalls=stalls+1;
   // Sample and increment use pre-command/pre-slew values above.
   if(fcw_valid) begin
    fcw_changes=fcw_changes+1; ft=fcw_in; fs=frequency_slew_step;
    if(!ADVANCED || !frequency_slew_enable || fs==0) begin fcw=ft; fb=0; end
    else fb=(fcw!=ft);
   end else if(ADVANCED && enable && fb) begin
    // Convert unsigned 32-bit operands without signed $itor ambiguity.
    distance={1'b0,ft}; distance=distance-{1'b0,fcw};
    if(distance<0) begin
     if(-distance<=fs) begin fcw=ft; fb=0; end else fcw=fcw-fs;
    end else if(distance<=fs) begin fcw=ft; fb=0; end else fcw=fcw+fs;
   end
   if(phase_valid) begin
    phase_changes=phase_changes+1; pt=phase_offset_in; ps=phase_slew_step;
    if(!ADVANCED || !phase_slew_enable || ps==0) begin offset=pt; pb=0; end
    else pb=(offset!=pt);
   end else if(ADVANCED && enable && pb) begin
    delta={1'b0,pt}; delta=delta-{1'b0,offset};
    if(delta>=2147483648.0) delta=delta-4294967296.0;
    if(delta< -2147483648.0) delta=delta+4294967296.0;
    if(delta<0) begin
     if(-delta<=ps) begin offset=pt; pb=0; end else offset=offset-ps;
    end else if(delta<=ps) begin offset=pt; pb=0; end else offset=offset+ps;
   end
  end
  #1;
  if(out_valid!==expected_valid || sine_out!==expected_s[15:0] || cosine_out!==expected_c[15:0]) fail;
  if(observed_acc!==acc || observed_fcw!==fcw || observed_offset!==offset) fail;
  if(ADVANCED && (frequency_busy!==fb || phase_busy!==pb)) fail;
  pending=0; for(i=0;i<3;i=i+1) if(valid[i]) pending=pending+1;
  if(accepted!=checked+discarded+pending) $fatal(1,"Sample accounting failed");
 end
endmodule
