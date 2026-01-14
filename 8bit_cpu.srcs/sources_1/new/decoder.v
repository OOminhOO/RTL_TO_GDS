// decoder.v
// 8bit 명령어(instr)를 받아서 CPU 내부 제어 신호로 변환하는 디코더
//
// instr 포맷 (8bit):
//   [7:5] opcode   : 연산 종류
//   [4]   dst      : 목적 레지스터 선택 (0 = R0, 1 = R1)
//   [3:0] imm      : 즉시값(imm4)
//
// 역할 요약:
// - opcode / dst / imm를 분리
// - LDI인지, ALU 연산 명령인지 구분
// - ALU opcode, 레지스터 write_enable, use_imm 등의 제어 신호 생성

`default_nettype none
module decoder (
    input  wire       clk,
    input  wire       reset,
    input  wire       ena,          // 1일 때만 새 instr를 해석
    input  wire [7:0] instr,        // ROM에서 가져온 명령어

    output reg  [2:0] alu_opcode,   // ALU로 보낼 연산 종류
    output reg        dst_sel,      // 목적 레지스터 선택 (0=R0, 1=R1)
    output reg  [3:0] imm4,         // 즉시값(하위 4bit)
    output reg        alu_enable,   // ALU를 사용할지 여부
    output reg        write_enable, // 레지스터를 갱신할지 여부
    output reg        use_imm       // WB에서 imm4를 쓸지(ALU 결과 대신)
);

    // 명령어 비트 필드 분리
    wire [2:0] opcode = instr[7:5]; // 상위 3bit: 연산 종류
    wire       dst    = instr[4];   // 목적 레지스터 선택
    wire [3:0] imm    = instr[3:0]; // 즉시값

    // 동기식 디코딩: 클럭 상승엣지마다 instr를 해석
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            // 리셋 시 모든 제어 신호 초기화
            alu_opcode   <= 3'b000;
            dst_sel      <= 1'b0;
            imm4         <= 4'b0000;
            alu_enable   <= 1'b0;
            write_enable <= 1'b0;
            use_imm      <= 1'b0;

        end else if (ena) begin
            // ena=1일 때만 새로운 명령어를 디코딩
            dst_sel <= dst;   // 목적 레지스터(R0/R1)
            imm4    <= imm;   // 즉시값 저장

            case (opcode)
                3'b000: begin
                    // LDI dst, imm  (즉시값 로드 명령)
                    // - ALU는 사용하지 않고
                    // - dst 레지스터에 imm4를 바로 기록
                    alu_opcode   <= 3'b000; // 의미 없음(사용 안 함)
                    alu_enable   <= 1'b0;   // ALU 비활성화
                    write_enable <= 1'b1;   // 레지스터 갱신 O
                    use_imm      <= 1'b1;   // WB에서 imm4를 데이터로 사용
                end

                // 아래 opcode들은 모두 ALU 연산 명령으로 처리
                3'b001, // ADD
                3'b010, // SUB
                3'b011, // AND
                3'b100, // OR
                3'b101, // XOR
                3'b110, // MUL
                3'b111: // DIV
                begin
                    // ALU 명령 공통 처리
                    alu_opcode   <= opcode; // ALU opcode = instr opcode
                    alu_enable   <= 1'b1;   // ALU 활성화
                    write_enable <= 1'b1;   // 연산 결과를 레지스터에 기록
                    use_imm      <= 1'b0;   // WB에서 ALU 결과를 사용
                end

                default: begin
                    // 이론상 도달하지 않는 경우 (방어용)
                    alu_opcode   <= 3'b000;
                    alu_enable   <= 1'b0;
                    write_enable <= 1'b0;
                    use_imm      <= 1'b0;
                end
            endcase

        end else begin
            // ena=0이면 새 명령어는 해석하지 않고,
            // ALU/레지스터 갱신을 잠시 멈춘다.
            alu_enable   <= 1'b0;
            write_enable <= 1'b0;
            use_imm      <= 1'b0;
        end
    end
endmodule



//// decoder.v
//// 8bit 명령어(instr)를 받아서 CPU 내부 제어 신호로 변환하는 디코더
////
//// instr 포맷 (8bit):
////   [7:5] opcode   : 연산 종류
////   [4]   dst      : 목적 레지스터 선택 (0 = R0, 1 = R1)
////   [3:0] imm      : 즉시값(imm4)

//`define default_netname none

//module decoder (
//    input  wire       clk,       // 지금은 안 쓰이지만 포트는 유지
//    input  wire       reset,
//    input  wire       ena,       // 1일 때만 새 instr를 해석
//    input  wire [7:0] instr,     // ROM에서 가져온 명령어

//    output reg  [2:0] alu_opcode,   // ALU로 보낼 연산 종류
//    output reg        dst_sel,      // 목적 레지스터 선택 (0=R0, 1=R1)
//    output reg  [3:0] imm4,         // 즉시값(하위 4bit)
//    output reg        alu_enable,   // ALU를 사용할지 여부
//    output reg        write_enable, // 레지스터를 갱신할지 여부
//    output reg        use_imm       // WB에서 imm4를 쓸지(ALU 결과 대신)
//);

//    // 명령어 비트 필드 분리
//    wire [2:0] opcode = instr[7:5]; // 상위 3bit: 연산 종류
//    wire       dst    = instr[4];   // 목적 레지스터 선택
//    wire [3:0] imm    = instr[3:0]; // 즉시값

//    // *** 조합형 디코딩 ***
//    // instr / ena / reset / opcode 등이 바뀔 때마다 즉시 제어신호가 바뀜
//    always @* begin
//        // 기본값(디폴트) 세팅: 아무 일도 안 하는 상태
//        alu_opcode   = 3'b000;
//        dst_sel      = 1'b0;
//        imm4         = 4'b0000;
//        alu_enable   = 1'b0;
//        write_enable = 1'b0;
//        use_imm      = 1'b0;

//        if (reset) begin
//            // reset 동안은 기본값 그대로 유지
//        end
//        else if (ena) begin
//            // ena=1일 때만 새 instr 디코딩
//            dst_sel = dst;
//            imm4    = imm;

//            case (opcode)
//                3'b000: begin
//                    // LDI dst, imm  (즉시값 로드 명령)
//                    // - ALU는 사용하지 않고
//                    // - dst 레지스터에 imm4를 바로 기록
//                    alu_opcode   = 3'b000; // 의미 없음(사용 안 함)
//                    alu_enable   = 1'b0;   // ALU 비활성화
//                    write_enable = 1'b1;   // 레지스터 갱신 O
//                    use_imm      = 1'b1;   // WB에서 imm4를 데이터로 사용
//                end

//                // 아래 opcode들은 모두 ALU 연산 명령으로 처리
//                3'b001, // ADD
//                3'b010, // SUB
//                3'b011, // AND
//                3'b100, // OR
//                3'b101, // XOR
//                3'b110, // MUL
//                3'b111: // DIV
//                begin
//                    // ALU 명령 공통 처리
//                    alu_opcode   = opcode; // ALU opcode = instr opcode
//                    alu_enable   = 1'b1;   // ALU 활성화
//                    write_enable = 1'b1;   // 연산 결과를 레지스터에 기록
//                    use_imm      = 1'b0;   // WB에서 ALU 결과를 사용
//                end

//                default: begin
//                    // 방어 코드: 위에 디폴트값이 이미 들어가 있음
//                end
//            endcase
//        end
//        // ena=0이면 기본값(아무 동작 안 함) 유지
//    end

//endmodule


