// prog_rom.v
// 4bit 주소 -> 8bit 명령어를 출력하는 간단한 프로그램 ROM
// - 총 16워드(0~15) 크기
// - PC에서 들어오는 addr를 사용해 instr를 출력
//
// ISA 포맷 (8bit):
//   [7:5] opcode   : 연산 종류
//   [4]   dst_sel  : 목적 레지스터 선택 (0=R0, 1=R1)
//   [3:0] imm4     : 즉시값 (LDI에서 사용)
//
// opcode 정의:
//   000 : LDI (Load Immediate)
//   001 : ADD
//   010 : SUB
//   011 : AND
//   100 : OR
//   101 : XOR
//   110 : MUL
//   111 : DIV

`default_nettype none
module prog_rom (
    input  wire [3:0] addr,   // PC에서 들어오는 주소 (0~15)
    output reg  [7:0] instr   // 해당 주소의 명령어 출력
);

    // 테스트용 프로그램 시퀀스:
    // 0: LDI R0, 6   → R0 = 6   (a 저장)
    // 1: LDI R1, 3   → R1 = 3   (b 저장)
    // 2: ADD R0,R1   → R0 = 6 + 3 = 9
    // 3: SUB R0,R1   → R0 = 9 - 3 = 6
    // 4: MUL R0,R1   → R0 = 6 * 3 = 18
    // 5: DIV R0,R1   → R0 = 18 / 3 = 6
    // 6: AND R0,R1   → R0 = 6 & 3 = 2
    // 7: XOR R0,R1   → R0 = 2 ^ 3 = 1
    // 8~15: 의미 없는 더미 명령(DIV R0,R1)로 채움

    always @* begin
        case (addr)
            // 0: LDI R0, 6
            // opcode=000(LDI), dst_sel=0(R0), imm4=0110(6)
            // => 8'b0000_0110 = 0x06
            4'd0: instr = 8'b0000_0110;

            // 1: LDI R1, 3
            // opcode=000(LDI), dst_sel=1(R1), imm4=0011(3)
            // => 8'b0001_0011 = 0x13
            4'd1: instr = 8'b0001_0011;

            // 2: ADD R0,R1
            // opcode=001(ADD), dst_sel=0(R0), imm4=0000(무시)
            // => 8'b0010_0000 = 0x20
            4'd2: instr = 8'b0010_0000;

            // 3: SUB R0,R1
            // opcode=010(SUB), dst_sel=0(R0)
            // => 8'b0100_0000 = 0x40
            4'd3: instr = 8'b0100_0000;

            // 4: MUL R0,R1
            // opcode=110(MUL), dst_sel=0(R0)
            // => 8'b1100_0000 = 0xC0
            4'd4: instr = 8'b1100_0000;

            // 5: DIV R0,R1
            // opcode=111(DIV), dst_sel=0(R0)
            // => 8'b1110_0000 = 0xE0
            4'd5: instr = 8'b1110_0000;

            // 6: AND R0,R1
            // opcode=011(AND), dst_sel=0(R0)
            // => 8'b0110_0000 = 0x60
            4'd6: instr = 8'b0110_0000;

            // 7: XOR R0,R1
            // opcode=101(XOR), dst_sel=0(R0)
            // => 8'b1010_0000 = 0xA0
            4'd7: instr = 8'b1010_0000;

            // 8~15: 더미 명령 (현재는 DIV R0,R1)
            default: instr = 8'b1110_0000;  // DIV R0,R1
        endcase
    end

endmodule
