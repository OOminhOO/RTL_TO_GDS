`timescale 1ns/1ps
`define default_netname none

// tb_alu.v
// -----------------------------------------
// 8bit ALU 단위 테스트벤치
// - a=6, b=3 고정해두고 opcode를 바꿔가며 결과 확인
// - ADD, SUB, AND, OR, XOR, MUL, DIV 동작 검증
// - DIV에서 b=0일 때 0xFF 나오는지도 체크
// -----------------------------------------
module tb_alu;

    // ALU 입력
    reg  [7:0] a;        // 피연산자 A
    reg  [7:0] b;        // 피연산자 B
    reg  [2:0] opcode;   // 연산 코드
    reg        ena;      // ALU enable

    // ALU 출력
    wire [7:0] result;   // 연산 결과

    // DUT 인스턴스
    alu u_alu (
        .a     (a),
        .b     (b),
        .opcode(opcode),
        .ena   (ena),
        .result(result)
    );

    // 테스트 시퀀스
    initial begin

        // 초기값
        a      = 8'd6;   // ROM 시퀀스에서 a=6, b=3 기준이라 맞춰줌
        b      = 8'd3;
        opcode = 3'b000;
        ena    = 1'b0;

        #10;

        // 1) ena=0일 때는 무조건 result=0 나와야 함
        $display("=== ena=0 구간 (결과는 항상 0이어야 함) ===");
        opcode = 3'b001; #10;
        opcode = 3'b010; #10;
        opcode = 3'b111; #10;

        // 2) ena=1로 켜고, 각 opcode별 결과 확인
        $display("\n=== ALU 연산 테스트 (a=6, b=3) ===");
        ena = 1'b1;

        // ADD: 6 + 3 = 9
        opcode = 3'b001; #10;

        // SUB: 6 - 3 = 3
        opcode = 3'b010; #10;

        // AND: 6 & 3 = 2 (0110 & 0011 = 0010)
        opcode = 3'b011; #10;

        // OR: 6 | 3 = 7 (0110 | 0011 = 0111)
        opcode = 3'b100; #10;

        // XOR: 6 ^ 3 = 5 (0110 ^ 0011 = 0101)
        opcode = 3'b101; #10;

        // MUL: 6 * 3 = 18 (0x12)
        opcode = 3'b110; #10;

        // DIV: 6 / 3 = 2
        opcode = 3'b111; #10;

        // 3) DIV에서 b=0인 경우 보호 동작 확인 (0xFF 나와야 함)
        $display("\n=== DIV 0 보호 동작 테스트 (b=0) ===");
        a      = 8'd10;
        b      = 8'd0;
        opcode = 3'b111;  // DIV
        #10;

        $finish;
    end

    // 모니터링: 상태를 로그로 출력
    initial begin
        $display(" time | ena | opcode |   a   b  | result");
        $display("-----------------------------------------");
        $monitor("%4t |  %b  |  %03b  | %3d %3d |  %3d (0x%02h)",
                 $time, ena, opcode, a, b, result, result);
    end

endmodule
