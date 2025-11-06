# RTL_TO_GDS

MobaXterm에서 Cadence Xcelium 실행 alu verliog 모듈 및 테스트 벤치 시뮬레이션.

```
vi editor
-:set number     //모바엑스텀 줄번호 보이게

vi alu.v       //alu.v 파일 만들기
```
---
**alu.v 코드**
<details>
<summary>펼치기/접기 **alu.v** </summary>
``` v

// 계산기
// alu.v

//`define default_netname none
`timescale 1ns / 1ps
`default_nettype none

(* keep_hierarchy *)
module ALU(
    // 입력 정의(ALU)
    input wire [7:0] a,
    input wire [7:0] b,
    input wire [2:0] opcode,
    input wire ena,

    output reg [15:0] result
    );

    // opcode
    // 000 - (+)
    // 001 - (-)
    // 010 - (*)
    // 011 - (/)
    // 100 - (%)
    // 101 - IF(==)
    // 110 - (>)
    // 111 - (<)

    // 미리 확장/보조 신호
    wire [15:0] a16 = {8'b0, a};
    wire [15:0] b16 = {8'b0, b};
    wire [15:0] multiply_temp = a * b;   // 8x8=16b
    wire        div_by_zero   = (b == 8'h00);

    always @(*) begin
        result = 16'h0000;
        if (ena) begin
            case (opcode)
                3'b000: result = a16 + b16;                                  // ★ 핵심 수정
                3'b001: result = {8'b0, (a - b)};                             // 8b wrap을 16b로 zero-extend
                3'b010: result = multiply_temp;
                3'b011: result = div_by_zero ? 16'h0000 : {8'b0, (a / b)};
                3'b100: result = div_by_zero ? 16'h0000 : {8'b0, (a % b)};
                3'b101: result = (a == b) ? 16'h0001 : 16'h0000;
                3'b110: result = (a >  b) ? 16'h0001 : 16'h0000;
                3'b111: result = (a <  b) ? 16'h0001 : 16'h0000;
                default: result = 16'h0000;
            endcase
        end
    end

    // 곱셈과 0 나눔 벡터
    //wire [15:0] multiply_temp = a * b;
    //wire div_by_zero = (b == 8'h00);

    //always @(*) begin
    //    // 기본값 세팅
    //    result = 16'b0000;
    //    if (ena) begin
    //        case (opcode)
    //            // 데이터 업데이트 // 8진수 > 16 진수 변경
    //            3'b000: result = {{8{1'b0}}, a + b};
    //            3'b001: result = {{8{1'b0}}, a - b};
    //            3'b010: result = multiply_temp; 
    //            3'b011: result = div_by_zero ? 16'b0000 : {{8{1'b0}}, a / b};
    //            3'b100: result = div_by_zero ? 16'b0000 : {{8{1'b0}}, a % b}; 
    //            3'b101: result = (a == b) ? 16'h0001 : 16'h0000;
    //            3'b110: result = (a > b) ? 16'h0001 : 16'h0000;
    //            3'b111: result = (a < b) ? 16'h0001 : 16'h0000;
    //            // 비정의 코드 반환
    //            default: result = 16'h0000;
    //        endcase
    //    end
    //end
    
endmodule  

```


</details>



``` txt
//work 폴더 만들기 그리고 work폴더로 이동
mkdir -p work
cd work

xrun -gui -access +rwc ../alu.v  -log alu_sim_gui.log &    //Xcelium 시뮬레이터 실행

옵션 및 인자           설명
---------------------------------------------------------------
xrun                  Cadence Xcelium 시뮬레이터 실행 명령
-gui                  GUI 모드로 실행 (파형 보기 등 그래픽 인터페이스 제공)
-access +rwc          신호에 대해 읽기(Read), 쓰기(Write), 연결(Connection) 권한 부여
../alu.v              시뮬레이션에 사용할 Verilog 소스 파일 (ALU 모듈)
-log alu_sim_gui.log  시뮬레이션 로그를 해당 파일에 저장
&                     명령을 백그라운드에서 실행 (터미널을 점유하지 않음)


```
