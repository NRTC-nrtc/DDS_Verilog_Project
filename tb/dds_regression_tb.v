`timescale 1ns/1ps
module dds_regression_tb #(parameter ROM_FILE="/home/ali/Desktop/ali/DDS_Verilog_Project/DDS_Verilog_Project/mem/sine_lut.hex");
 reg clk=0; always #5 clk=~clk;
 reg rst=1,enable=0,fcw_valid=0,phase_valid=0;
 reg [31:0] fcw_in=0,phase_offset_in=0;
 reg frequency_slew_enable=0,phase_slew_enable=0;
 reg [31:0] frequency_slew_step=0,phase_slew_step=0;
 wire signed [15:0] s,c,as,ac;
 wire v,av,fb,pb;
 integer seed=32'h12345678,i,j,fd,n,previous_s,crossings;
 reg [31:0] random_word;
 real measured;
 dds_top #(12,ROM_FILE) dut(clk,rst,enable,fcw_in,fcw_valid,phase_offset_in,phase_valid,s,c,v);
 dds_top_advanced #(12,ROM_FILE) advanced(clk,rst,enable,fcw_in,fcw_valid,phase_offset_in,phase_valid,frequency_slew_enable,frequency_slew_step,phase_slew_enable,phase_slew_step,as,ac,av,fb,pb);
 dds_reference baseline_check(clk,rst,enable,fcw_in,phase_offset_in,fcw_valid,phase_valid,frequency_slew_enable,phase_slew_enable,frequency_slew_step,phase_slew_step,s,c,v,dut.engine.phase_acc,dut.active_fcw,dut.phase_offset,1'b0,1'b0);
 dds_reference #(1) advanced_check(clk,rst,enable,fcw_in,phase_offset_in,fcw_valid,phase_valid,frequency_slew_enable,phase_slew_enable,frequency_slew_step,phase_slew_step,as,ac,av,advanced.engine.phase_acc,advanced.active_fcw,advanced.phase_offset,fb,pb);
 task wait_cycles; input integer count; begin repeat(count) @(negedge clk); end endtask
 task command; input [31:0] f,p; begin
  @(negedge clk); fcw_in=f; phase_offset_in=p; fcw_valid=1; phase_valid=1;
  @(negedge clk); fcw_valid=0; phase_valid=0;
 end endtask
 task reset_core; begin
  @(negedge clk); rst=1; wait_cycles(2); rst=0;
 end endtask
 task test_frequency; input [31:0] word; input real nominal;
  begin
   command(word,0); wait_cycles(10); crossings=0; previous_s=s;
   for(j=0;j<20000;j=j+1) begin
    @(negedge clk);
    if(v && previous_s<0 && s>=0) crossings=crossings+1;
    previous_s=s;
   end
   measured=crossings*100000000.0/20000.0;
   if((measured-nominal)>5000.1 || (nominal-measured)>5000.1) $fatal(1,"Frequency crossing check failed");
   $display("Frequency FCW=%h target=%0f measured=%0f Hz crossings=%0d",word,nominal,measured,crossings);
  end
 endtask
 initial begin
  if($test$plusargs("vcd")) begin $dumpfile("results/dds.vcd"); $dumpvars(0,dds_regression_tb); end
  wait_cycles(3); rst=0; enable=1;
  test_frequency(32'h00418937,100000.0);
  test_frequency(32'h0147ae14,500000.0);
  test_frequency(32'h028f5c29,1000000.0);
  test_frequency(32'h051eb852,2000000.0);
  test_frequency(32'h0ccccccd,5000000.0);
  test_frequency(32'h1999999a,10000000.0);
  // Continuous transitions, with no reset or stalls.
  command(32'h028f5c29,0); wait_cycles(301);
  command(32'h0ccccccd,0); wait_cycles(301);
  command(32'h051eb852,0); wait_cycles(301);
  command(32'h1999999a,0); wait_cycles(301);
  command(32'h0147ae14,0); wait_cycles(301);
  command(32'h1999999a,0); command(32'h051eb852,0);
  command(32'h028f5c29,32'h20000000); command(32'h028f5c29,32'h40000000);
  command(32'h028f5c29,32'h80000000); command(32'h028f5c29,32'hf8e38e39);
  command(32'h028f5c29,32'h071c71c7);
  @(negedge clk); enable=0; wait_cycles(17);
  command(32'h0ccccccd,32'hc0000000); wait_cycles(9); enable=1; wait_cycles(200);
  // Exact all-address sweep (covers every quadrant boundary and accumulator wrap).
  reset_core(); command(32'h00040000,0); wait_cycles(16390);
  command(0,0); wait_cycles(20); command(1,32'hffffffff); wait_cycles(20);
  command(32'h7fffffff,0); wait_cycles(100);
  command(32'h80000000,0); wait_cycles(100);
  command(32'hffffffff,0); wait_cycles(100);
  // Smooth frequency ramp and circular 350 -> 10 degree phase movement.
  frequency_slew_enable=0; phase_slew_enable=0;
  command(32'h028f5c29,32'hf8e38e39); wait_cycles(10);
  frequency_slew_enable=1; phase_slew_enable=1;
  frequency_slew_step=32'h00100000; phase_slew_step=32'h038e38e4;
  command(32'h0ccccccd,32'h071c71c7); wait_cycles(200);
  command(32'h028f5c29,0); wait_cycles(200);
  command(32'h051eb852,32'h20000000); wait_cycles(50);
  command(32'h051eb852,32'h40000000); wait_cycles(50);
  command(32'h051eb852,32'h80000000); wait_cycles(50);
  command(32'h1999999a,32'hf8e38e39); wait_cycles(2); reset_core();
  // Consecutive command cycles and reset during commands.
  fcw_valid=1; phase_valid=1;
  for(i=0;i<12;i=i+1) begin @(negedge clk); fcw_in=i*32'h01234567; phase_offset_in=i*32'h10000000; end
  rst=1; wait_cycles(2); rst=0; fcw_valid=0; phase_valid=0;
  for(i=0;i<10000;i=i+1) begin
   @(negedge clk);
   random_word=$random(seed); enable=random_word[0] | random_word[1]; rst=(random_word[9:2]==0);
   fcw_valid=random_word[10]; phase_valid=random_word[11];
   frequency_slew_enable=random_word[12]; phase_slew_enable=random_word[13];
   fcw_in=$random(seed); phase_offset_in=$random(seed);
   frequency_slew_step=$random(seed); phase_slew_step=$random(seed);
  end
  @(negedge clk); rst=0; enable=1; fcw_valid=0; phase_valid=0;
  frequency_slew_enable=0; phase_slew_enable=0;
  frequency_slew_step=0; phase_slew_step=0;
  command(32'h02890000,0); wait_cycles(20);
  // 65536 coherent samples: bin 649, Fs=100 MHz.
  fd=$fopen("results/waveform.csv","w"); if(!fd) $fatal(1,"Cannot create waveform file");
  $fdisplay(fd,"sine,cosine");
  for(n=0;n<65536;n=n+1) begin
   @(posedge clk); #2;
   if(!v) $fatal(1,"Invalid sample during spectral capture");
   $fdisplay(fd,"%0d,%0d",s,c);
  end
  $fclose(fd);
  @(negedge clk); enable=0; wait_cycles(5);
  $display("PASS baseline cycles=%0d accepted=%0d checked=%0d discarded=%0d pending=%0d FCW_commands=%0d phase_commands=%0d resets=%0d stalls=%0d",baseline_check.cycles,baseline_check.accepted,baseline_check.checked,baseline_check.discarded,baseline_check.accepted-baseline_check.checked-baseline_check.discarded,baseline_check.fcw_changes,baseline_check.phase_changes,baseline_check.resets,baseline_check.stalls);
  $display("PASS advanced checked=%0d: independent control, busy, circular slew and all output cycles",advanced_check.checked);
  $finish;
 end
endmodule
