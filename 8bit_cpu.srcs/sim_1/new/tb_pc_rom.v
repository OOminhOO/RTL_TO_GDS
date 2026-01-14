`timescale 1ns / 1ps
`define default_netname none

module cpu_core_tb;

    // 입력
    reg clk;
    reg reset;
    reg ena;

    // PC / ROM
    wire [3:0] pc;
    wire [7:0] instr;

    // DECODER 출력
    wire [2:0] alu_opcode;
    wire       dst_sel;
    wire [3:0] imm4;
    wire       alu_enable;
    wire       write_enable;
    wire       use_imm;

    // REGFILE / ALU
    wire [7:0] R0;
    wire [7:0] R1;
    wire [7:0] alu_result;

    // =====================================
    // DUT 인스턴스
    // =====================================

    // 1) PC: 0~7 까지 카운트
    pc #(
        .WIDTH(4),
        .LAST(4'd7)
    ) pc_inst (
        .clk   (clk),
        .reset (reset),
        .ena   (ena),     // CPU 전체 enable
        .pc    (pc)
    );

    // 2) ROM: PC → instr
    prog_rom rom_inst (
        .addr  (pc),
        .instr (instr)
    );

    // 3) DECODER: instr → 제어신호
    decoder dec_inst (
        .clk          (clk),
        .reset        (reset),
        .ena          (ena),
        .instr        (instr),
        .alu_opcode   (alu_opcode),
        .dst_sel      (dst_sel),
        .imm4         (imm4),
        .alu_enable   (alu_enable),
        .write_enable (write_enable),
        .use_imm      (use_imm)
    );

    // 4) REGFILE: R0/R1 저장
    //    wb_data: LDI면 imm, 아니면 ALU 결과
    wire [7:0] wb_data =
        use_imm ? {4'b0000, imm4} : alu_result;

    regfile reg_inst (
        .clk          (clk),
        .reset        (reset),
        .ena          (ena),
        .write_enable (write_enable),
        .dst_sel      (dst_sel),
        .data_in      (wb_data),
        .R0           (R0),
        .R1           (R1)
    );

    // 5) ALU: R0/R1 + opcode
    alu alu_inst (
        .a      (R0),
        .b      (R1),
        .opcode (alu_opcode),
        .ena    (alu_enable),
        .result (alu_result)
    );


    // =====================================
    // 클럭 생성
    // =====================================
    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;  // 10ns 주기 = 100MHz
    end

    // =====================================
    // stimulus (reset / ena)
    // =====================================
    initial begin
        reset = 1'b1;
        ena   = 1'b0;

        // 20ns 동안 리셋
        #20;
        reset = 1'b0;
        ena   = 1'b1;

        // 한 400ns 정도 돌려보기 (40클럭)
        #400;
        $finish;
    end

    // =====================================
    // 모니터링 (콘솔 출력)
    // =====================================

    wire [2:0] instr_opcode = instr[7:5];
    wire       instr_dst    = instr[4];
    wire [3:0] instr_imm4   = instr[3:0];

    initial begin
        $display(" time | pc | instr | i_op dst imm | dec_op ALU_en WE use_imm | R0  R1  | ALU");
        $display("----------------------------------------------------------------------------------");
        $monitor("%4t | %1d  | 0x%02h |  %03b   %b  0x%01h |   %03b    %b    %b    %b   | %3d %3d | %3d",
                 $time,
                 pc,
                 instr,
                 instr_opcode, instr_dst, instr_imm4,
                 alu_opcode, alu_enable, write_enable, use_imm,
                 R0, R1, alu_result);
    end

endmodule
