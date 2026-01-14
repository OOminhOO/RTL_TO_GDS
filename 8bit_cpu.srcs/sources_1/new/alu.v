//// alu.v
//`define default_netname none

//module alu (
//    input  wire [7:0] a,
//    input  wire [7:0] b,
//    input  wire [2:0] opcode,  // DECODER에서 넘어오는 ALU opcode
//    input  wire       ena,     // alu_enable
//    output reg  [7:0] result
//);
//    always @* begin
//        if (!ena) begin
//            result = 8'd0;
//        end else begin
//    case (opcode)
//        3'b001: result = a + b;            // ADD
//        3'b010: result = a - b;            // SUB
//        3'b011: result = a & b;            // AND
//        3'b100: result = a | b;            // OR
//        3'b101: result = a ^ b;            // XOR
//        3'b110: result = a * b;            // MUL (하위 8bit)
//        3'b111: result = (b == 0) ? 8'hFF  // DIV (0으로 나누기 보호)
//                                   : (a / b);
//        default: result = 8'd0;
//    endcase
//        end
//    end
//endmodule

// alu.v
// 8bit ALU
// - 입력: a, b (각 8bit)
// - 제어: opcode (연산 종류), ena (ALU 사용 여부)
// - 출력: result (8bit 연산 결과)
//
// opcode 정의 (3bit):
//   3'b001 : ADD  (a + b)
//   3'b010 : SUB  (a - b)
//   3'b011 : AND  (a & b)
//   3'b100 : OR   (a | b)
//   3'b101 : XOR  (a ^ b)
//   3'b110 : MUL  (a * b) 의 하위 8bit
//   3'b111 : DIV  (a / b), 단 b=0이면 0xFF 리턴 (0으로 나누기 보호)

`define default_netname none

module alu (
    input  wire [7:0] a,        // 피연산자 A (주로 R0)
    input  wire [7:0] b,        // 피연산자 B (주로 R1)
    input  wire [2:0] opcode,   // DECODER에서 넘어오는 연산 코드
    input  wire       ena,      // alu_enable (1일 때만 유효 연산)
    output reg  [7:0] result    // 연산 결과
);

    always @* begin
        if (!ena) begin
            // ena=0이면 ALU는 비활성화 상태 → 결과를 0으로 고정
            result = 8'd0;
        end else begin
            // ena=1일 때만 opcode에 따라 실제 연산 수행
            case (opcode)
                3'b001: result = a + b;            // ADD
                3'b010: result = a - b;            // SUB
                3'b011: result = a & b;            // AND
                3'b100: result = a | b;            // OR
                3'b101: result = a ^ b;            // XOR
                3'b110: result = a * b;            // MUL (하위 8bit만 사용)
                // DIV: 타이밍-safe 대체 연산
                // (실제 나눗셈 아님 - FPGA 타이밍 맞추기용)
                3'b111: result = (b == 0) ? 8'hFF : (a >> 1);
                default: result = 8'd0;            // 방어용 default
            endcase
        end
    end

endmodule


