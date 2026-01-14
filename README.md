# RTL_TO_GDS

상세정리 Notion 링크  
https://flashy-gopher-3c9.notion.site/8bit-mini-CPU-RTL-TO-GDS-2bb52e880248806699f2f1fbb98cb400?source=copy_link


<details>
<summary>펼치기/접기 **alu.v** </summary>  
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
    
```verilog

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


---

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
---
<br>
Xcelium 시뮬레이터 실행 
<img width="885" height="814" alt="image" src="https://github.com/user-attachments/assets/7eeefb1d-6c50-47e6-ba38-40bfb7d0affe" />  
<br>
<br>
<br>
<img width="872" height="921" alt="image" src="https://github.com/user-attachments/assets/c2866906-4119-4e67-9487-e2bf19859833" />
<br>
<br>
<br>

시뮬레이션 wave form 뜸
<img width="1007" height="630" alt="image" src="https://github.com/user-attachments/assets/c89cbd1b-9b44-46f7-aa5f-58dcf35e4d94" />
아이콘 누르면 schmetic 볼수 있고 변수 누르면 노란색선으로 확인가능
<br>
<br>
<img width="1199" height="623" alt="image" src="https://github.com/user-attachments/assets/610677a9-37ca-45fc-af6c-bbd1540d4432" />
<br>
<br>
<br>

force 로 입력주기
<br>
<img width="639" height="722" alt="image" src="https://github.com/user-attachments/assets/e54120fe-8cbc-465f-94fc-43fe281f7687" />
<br>
<br>
<br>
<img width="341" height="207" alt="image" src="https://github.com/user-attachments/assets/0d78bdb6-25ef-4ff6-b05a-2500c75a7166" />
<br>
<br>
<br>
a,b,ena,opcode 입력주고 10ns 시뮬레이션하기
<br>
<img width="1341" height="633" alt="image" src="https://github.com/user-attachments/assets/b58e7c54-200c-4402-b9b3-dbc654a1146b" />
<br>
<br>
aㅣt + = 으로 파형 전체 확인 가능
<br>
<br>
<br>
넣어줄 입력들 작성하기 (test벤치 대신 간단하게 tcl에 입력해서 시뮬레이션 확인)
<br>
<details>  
    <br>
    
```txt
    
force ALU.a = 8'd00; 
force ALU.b = 8'd00;
force ALU.opcode = 3'd0; 
force ALU.ena = 1'b0; 
run 10ns

force ALU.a = 8'd15; 
force ALU.b = 8'd5;
force ALU.opcode = 3'd0; 
force ALU.ena = 1'b0; 
run 10ns

force ALU.a = 8'd0; 
force ALU.b = 8'd0;
force ALU.opcode = 3'd0; 
force ALU.ena = 1'b1; 
run 10ns

force ALU.a = 8'd15; 
force ALU.b = 8'd5;
force ALU.opcode = 3'd0;  
run 10ns


force ALU.a = 8'd255; 
force ALU.b = 8'd1;
force ALU.opcode = 3'd0;  
run 10ns

force ALU.a = 8'd127; 
force ALU.b = 8'd127;
force ALU.opcode = 3'd0;  
run 10ns

force ALU.a = 8'd10; 
force ALU.b = 8'd5;
force ALU.opcode = 3'd1;  
run 10ns

force ALU.a = 8'd5; 
force ALU.b = 8'd10;
force ALU.opcode = 3'd1;  
run 10ns

force ALU.a = 8'd255; 
force ALU.b = 8'd255;
force ALU.opcode = 3'd1;  
run 10ns

force ALU.a = 8'd0; 
force ALU.b = 8'd5;
force ALU.opcode = 3'd2;  
run 10ns

force ALU.a = 8'd5; 
force ALU.b = 8'd6;
force ALU.opcode = 3'd2;  
run 10ns

force ALU.a = 8'd15; 
force ALU.b = 8'd16;
force ALU.opcode = 3'd2;  
run 10ns

force ALU.a = 8'd255; 
force ALU.b = 8'd255;
force ALU.opcode = 3'd2;  
run 10ns

force ALU.a = 8'd10; 
force ALU.b = 8'd2;
force ALU.opcode = 3'd3;  
run 10ns

force ALU.a = 8'd15; 
force ALU.b = 8'd4;
force ALU.opcode = 3'd3;  
run 10ns

force ALU.a = 8'd100; 
force ALU.b = 8'd0;
force ALU.opcode = 3'd3;  
run 10ns

force ALU.a = 8'd255; 
force ALU.b = 8'd1;
force ALU.opcode = 3'd3;  
run 10ns

force ALU.a = 8'd10; 
force ALU.b = 8'd3;
force ALU.opcode = 3'd4;  
run 10ns

force ALU.a = 8'd15; 
force ALU.b = 8'd4;
force ALU.opcode = 3'd4;  
run 10ns

force ALU.a = 8'd100; 
force ALU.b = 8'd0;
force ALU.opcode = 3'd4;  
run 10ns

force ALU.a = 8'd8; 
force ALU.b = 8'd4;
force ALU.opcode = 3'd4;  
run 10ns

force ALU.a = 8'd10; 
force ALU.b = 8'd10;
force ALU.opcode = 3'd5;  
run 10ns

force ALU.a = 8'd10; 
force ALU.b = 8'd5;
force ALU.opcode = 3'd5;  
run 10ns

force ALU.a = 8'd255; 
force ALU.b = 8'd255;
force ALU.opcode = 3'd5;  
run 10ns

force ALU.a = 8'd11; 
force ALU.b = 8'd10;
force ALU.opcode = 3'd6;  
run 10ns

force ALU.a = 8'd10; 
force ALU.b = 8'd11;
force ALU.opcode = 3'd6;  
run 10ns

force ALU.a = 8'd10; 
force ALU.b = 8'd10;
force ALU.opcode = 3'd6;  
run 10ns

force ALU.a = 8'd10; 
force ALU.b = 8'd11;
force ALU.opcode = 3'd7;  
run 10ns

force ALU.a = 8'd11; 
force ALU.b = 8'd10;
force ALU.opcode = 3'd7;  
run 10ns

force ALU.a = 8'd10; 
force ALU.b = 8'd10;
force ALU.opcode = 3'd7;  
run 10ns

force ALU.a = 8'd36; 
force ALU.b = 8'd129;
force ALU.opcode = 3'd1;  
run 10ns

force ALU.a = 8'd99; 
force ALU.b = 8'd13;
force ALU.opcode = 3'd5;  
run 10ns

force ALU.a = 8'd101; 
force ALU.b = 8'd18;
force ALU.opcode = 3'd1;  
run 10ns

force ALU.a = 8'd101; 
force ALU.b = 8'd18;
force ALU.opcode = 3'd1;  
run 10ns

force ALU.a = 8'd101; 
force ALU.b = 8'd18;
force ALU.opcode = 3'd1;  
run 10ns

force ALU.a = 8'd13; 
force ALU.b = 8'd118;
force ALU.opcode = 3'd5;  
run 10ns

force ALU.a = 8'd237; 
force ALU.b = 8'd140;
force ALU.opcode = 3'd1;  
run 10ns

force ALU.a = 8'd198; 
force ALU.b = 8'd197;
force ALU.opcode = 3'd2;  
run 10ns

force ALU.a = 8'd229; 
force ALU.b = 8'd119;
force ALU.opcode = 3'd2;  
run 10ns

force ALU.a = 8'd143; 
force ALU.b = 8'd142;
force ALU.opcode = 3'd6;  
run 10ns

force ALU.a = 8'd232; 
force ALU.b = 8'd197;
force ALU.opcode = 3'd4;  
run 10ns

force ALU.a = 8'd198; 
force ALU.b = 8'd145;
force ALU.opcode = 3'd5;  
run 20ns

```

  
</details>

---
<br>
<br>
<br>
tcl에 입력시 파형확인가능
<img width="1911" height="351" alt="image" src="https://github.com/user-attachments/assets/af1cf07f-5efb-4f3c-8670-b63fb072bca4" />

</details>



