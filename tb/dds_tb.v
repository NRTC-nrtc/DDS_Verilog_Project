`timescale 1ns/1ps
module dds_tb #(parameter ROM_FILE="/home/ali/Desktop/ali/DDS_Verilog_Project/DDS_Verilog_Project/mem/sine_lut.hex");
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
 integer observation_cycles,sweep_fd,sweep_cycles,phase_fd,phase_capture;
 reg [3:0] test_stage=0;
 reg [31:0] phase_degrees=0;
 reg [31:0] previous_ramp_fcw;
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
   observation_cycles=(nominal<10000.0) ? 500000 : 20000;
   for(j=0;j<observation_cycles;j=j+1) begin
    @(negedge clk);
    if(v && previous_s<0 && s>=0) crossings=crossings+1;
    previous_s=s;
   end
   measured=crossings*100000000.0/observation_cycles;
   if((measured-nominal)>100000000.0/observation_cycles+0.1 || (nominal-measured)>100000000.0/observation_cycles+0.1) $fatal(1,"Frequency crossing check failed");
   $display("Frequency FCW=%h target=%0f measured=%0f Hz crossings=%0d",word,nominal,measured,crossings);
  end
 endtask
 task phase_test; input [31:0] degrees,word;
  begin
   phase_degrees=degrees;
   command(32'h028f5c29,word);
   // 4096 edges cover the longest 2048-step circular transition.
   for(phase_capture=0;phase_capture<4096;phase_capture=phase_capture+1) begin
    @(posedge clk); #2;
    $fdisplay(phase_fd,"%0t,%0d,%0d,%h,%h,%0d,%0d,%0d,%0d,%b,%b",$time,test_stage,degrees,dut.phase_offset,advanced.phase_offset,s,c,as,ac,v,av);
   end
   if(pb || dut.phase_offset!==word || advanced.phase_offset!==word) $fatal(1,"Phase target not reached");
   $display("PHASE mode=%0d degrees=%0d target=%h baseline=%h advanced=%h",test_stage,degrees,word,dut.phase_offset,advanced.phase_offset);
  end
 endtask
 initial begin
  if($test$plusargs("vcd")) begin $dumpfile("results/dds.vcd"); $dumpvars(0,dds_tb); end
  wait_cycles(3); rst=0; enable=1;
  test_stage=1;
  test_frequency(32'd42950,1000.0);
  test_frequency(32'd429497,10000.0);
  test_frequency(32'h00418937,100000.0);
  test_frequency(32'h0147ae14,500000.0);
  test_frequency(32'h028f5c29,1000000.0);
  test_frequency(32'h051eb852,2000000.0);
  test_frequency(32'h0ccccccd,5000000.0);
  test_frequency(32'h1999999a,10000000.0);
  // Frequency staircase for the simple core; no resets between updates.
  test_stage=2;
  command(32'd42950,0); wait_cycles(100000);
  command(32'd429497,0); wait_cycles(10000);
  command(32'd4294967,0); wait_cycles(2000);
  command(32'd42949673,0); wait_cycles(1000);
  command(32'd214748365,0); wait_cycles(1000);
  command(32'd429496730,0); wait_cycles(1000);
  // Advanced linear chirp: 1 kHz -> 10 MHz, approximately 100 Hz/edge.
  test_stage=3;
  command(32'd42950,0); wait_cycles(10);
  @(negedge clk); frequency_slew_enable=1; frequency_slew_step=32'd4295;
  command(32'd429496730,0);
  sweep_fd=$fopen("results/sweep.csv","w"); if(!sweep_fd) $fatal(1,"Cannot create sweep.csv");
  $fdisplay(sweep_fd,"time_ps,advanced_fcw_postedge,baseline_sine,baseline_cosine,advanced_sine,advanced_cosine,baseline_valid,advanced_valid");
  sweep_cycles=0; previous_ramp_fcw=advanced.active_fcw;
  while(fb) begin
   @(posedge clk); #2; sweep_cycles=sweep_cycles+1;
   if(advanced.active_fcw<previous_ramp_fcw || advanced.active_fcw>32'd429496730) $fatal(1,"Nonmonotonic sweep or overshoot");
   if(fb && advanced.active_fcw-previous_ramp_fcw!=32'd4295) $fatal(1,"Incorrect sweep step");
   previous_ramp_fcw=advanced.active_fcw;
   $fdisplay(sweep_fd,"%0t,%0d,%0d,%0d,%0d,%0d,%b,%b",$time,advanced.active_fcw,s,c,as,ac,v,av);
   if(sweep_cycles>100100) $fatal(1,"Sweep timeout");
  end
  $fclose(sweep_fd);
  if(advanced.active_fcw!==32'd429496730) $fatal(1,"Incorrect sweep endpoint");
  $display("SWEEP PASS: 1 kHz -> 10 MHz; FCW step=4295 (~100.00076 Hz/edge); edges=%0d",sweep_cycles);
  @(negedge clk); frequency_slew_enable=0; wait_cycles(10);
  // Immediate offsets in both cores; then gradual offsets in the advanced core.
  phase_fd=$fopen("results/phase_shift.csv","w"); if(!phase_fd) $fatal(1,"Cannot create phase_shift.csv");
  $fdisplay(phase_fd,"time_ps,mode,requested_degrees,baseline_offset_postedge_hex,advanced_offset_postedge_hex,sine,cosine,advanced_sine,advanced_cosine,valid,advanced_valid");
  test_stage=4; phase_slew_enable=0;
  phase_test(0,0); phase_test(45,32'h20000000); phase_test(90,32'h40000000);
  phase_test(180,32'h80000000); phase_test(270,32'hc0000000);
  phase_test(350,32'hf8e38e39); phase_test(10,32'h071c71c7);
  @(negedge clk); test_stage=5; phase_slew_enable=1; phase_slew_step=32'h00100000;
  phase_test(0,0); phase_test(45,32'h20000000); phase_test(90,32'h40000000);
  phase_test(180,32'h80000000); phase_test(270,32'hc0000000);
  phase_test(350,32'hf8e38e39); phase_test(10,32'h071c71c7);
  $fclose(phase_fd);
  @(negedge clk); phase_slew_enable=0; test_stage=6;
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
