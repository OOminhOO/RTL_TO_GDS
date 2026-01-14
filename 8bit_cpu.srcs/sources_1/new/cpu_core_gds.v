// cpu_core_gds.v
// GDS용 8bit Mini CPU 코어
// - UART, 스위치 모드, LED 디버그 등은 모두 제거
// - PC → ROM → Decoder → RegFile/ALU → Writeback 의 최소 구조만 남긴 버전
// - pc_out, r0_out, r1_out, alu_out 정도만 외부 핀으로 뽑아서 관찰 용도로 사용

`default_nettype none

module cpu_core_gds (
    input  wire       clk,      // 시스템 클럭
    input  wire       reset,    // 비동기 리셋
    input  wire       ena,      // 전체 CPU enable (필요 없으면 top에서 1'b1로 고정)

    // 관찰용 / 단순 I/O용 출력들
    output wire [3:0] pc_out,   // 현재 PC 값
    output wire [7:0] r0_out,   // 레지스터 R0
    output wire [7:0] r1_out,   // 레지스터 R1
    output wire [7:0] alu_out   // ALU 연산 결과
);

    //========================
    // 1) Program Counter
    //========================
    wire [3:0] pc;

    pc #(
        .WIDTH(4),
        .LAST (4'd7)      // ROM 주소 0~7까지만 사용
    ) u_pc (
        .clk  (clk),
        .reset(reset),
        .ena  (ena),
        .pc   (pc)
    );

    //========================
    // 2) Instruction ROM
    //========================
    wire [7:0] instr;

    prog_rom u_rom (
        .addr (pc),       // PC를 주소로 사용
        .instr(instr)     // 현재 명령어
    );

    //========================
    // 3) Decoder
    //========================
    wire [2:0] alu_opcode;
    wire       dst_sel;
    wire [3:0] imm4;
    wire       alu_enable;
    wire       write_enable;
    wire       use_imm;

    decoder u_dec (
        .clk         (clk),
        .reset       (reset),
        .ena         (ena),
        .instr       (instr),
        .alu_opcode  (alu_opcode),
        .dst_sel     (dst_sel),
        .imm4        (imm4),
        .alu_enable  (alu_enable),
        .write_enable(write_enable),
        .use_imm     (use_imm)
    );

    //========================
    // 4) Register File (R0, R1)
    //========================
    wire [7:0] R0;
    wire [7:0] R1;

    wire [7:0] wb_data;   // Writeback 데이터 (imm 또는 ALU 결과) wb_data = use_imm ? {4'b0000, imm4} : alu_result;

    regfile u_reg (
        .clk         (clk),
        .reset       (reset),
        .ena         (ena),
        .write_enable(write_enable),
        .dst_sel     (dst_sel),
        .data_in     (wb_data),
        .R0          (R0),
        .R1          (R1)
    );

    //========================
    // 5) ALU
    //========================
    wire [7:0] alu_result;

    alu u_alu (
        .a     (R0),          // 기본적으로 R0, R1을 피연산자로 사용
        .b     (R1),
        .opcode(alu_opcode),
        .ena   (alu_enable),
        .result(alu_result)
    );

    //========================
    // 6) Writeback 경로 선택
    //    - LDI : imm4 사용
    //    - 그 외 ALU 명령 : ALU 결과 사용
    //========================
    assign wb_data = use_imm ? {4'b0000, imm4} : alu_result;

    //========================
    // 7) 관찰용 출력 매핑
    //========================
    assign pc_out  = pc;
    assign r0_out  = R0;
    assign r1_out  = R1;
    assign alu_out = alu_result;

endmodule
