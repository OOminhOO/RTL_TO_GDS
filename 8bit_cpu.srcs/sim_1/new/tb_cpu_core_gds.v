`timescale 1ns/1ps
`define default_netname none

module tb_cpu_core_gds;

 reg       clk;      // 시스템 클럭
 reg       reset;    // 비동기 리셋
 reg       ena;      // 전체 CPU enable (필요 없으면 top에서 1'b1로 고정)

 wire [3:0] pc_out;   // 현재 PC 값
 wire [7:0] r0_out;   // 레지스터 R0
 wire [7:0] r1_out;   // 레지스터 R1
 wire [7:0] alu_out;   // ALU 연산 결과
 
    cpu_core_gds u_cpu_core_gds(
    .clk(clk),
    .reset(reset),
    .ena(ena),
    .pc_out(pc_out),
    .r0_out(r0_out),
    .r1_out(r1_out),
    .alu_out(alu_out)
    );
    
    always #5 clk = ~clk;
    
    initial begin
    clk = 0;
    reset = 1;
    ena = 0;
    #20;
    reset = 0;
    #10;
    ena = 1;
    #160; 
    reset =1;
    #20;
    $finish;
    end         
    
    initial begin
    $display("time  |   reset   ena |   pc_out  |   r0_out  r1_out  alu_out  ");
    $display("---------------------------------------------------------------");
    $monitor("%4t   |   %b     %b  | %04b    |   %08b    %08b  %08b  ",
             $time, reset, ena, pc_out, r0_out, r1_out, alu_out);
    end  

endmodule