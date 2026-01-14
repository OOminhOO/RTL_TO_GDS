//module tb_decoder;

//reg     clk;
//reg       reset;
//reg      ena;          // 1일 때만 새 instr를 해석

//wire [7:0] instr;        // ROM에서 가져온 명령어
//wire  [2:0] alu_opcode;   // ALU로 보낼 연산 종류
//wire        dst_sel;      // 목적 레지스터 선택 (0=R0, 1=R1)
//wire  [3:0] imm4;         // 즉시값(하위 4bit)
//wire        alu_enable;   // ALU를 사용할지 여부
//wire        write_enable; // 레지스터를 갱신할지 여부
//wire        use_imm;       // WB에서 imm4를 쓸지(ALU 결과 대신)

//  decoder u_decoder (
//                    .clk(clk),
//                    .reset(reset),
//                    .ena(ena),
//                    .instr(instr),
//                    .alu_opcode(alu_opcode),
//                    .dst_sel(dst_sel),
//                    .imm4(imm4),
//                    .alu_enable(alu_enable),
//                    .write_enable(write_enable),
//                    .use_imm(use_imm)
//                    );
          
//    wire [3:0] pc;   // WIDTH=4 기준

//    // DUT 인스턴스
//    pc #(
//        .WIDTH(4),
//        .LAST (4'd7)   // 0~7까지 증가 후 다시 0
//    ) u_pc (
//        .clk  (clk),
//        .reset(reset),
//        .ena  (ena),
//        .pc   (pc)
//    );

    
//    prog_rom u_progrom (
//        .addr(pc), 
//        .instr(instr)
//    );
    
//    initial begin
//    clk =0;
//    reset = 0;
//    ena =0;
//    #10;
//    ena =1;
//    #30;
//    reset =1;
//    #20;
//    reset =0;
//    #100;
//    ena =0;
//    #20;
//    ena =1;
//    #200;
//    $finish;
//    end 
    
//    always #5 clk = ~clk;


//endmodule

`timescale 1ns/1ps
`define default_netname none

// tb_decoder.v
// -------------------------------------------
// decoder + pc + prog_rom 통합 테스트벤치
// - PC가 0~7까지 돌면서 ROM에서 instr 읽기
// - decoder가 opcode/dst/imm/control 신호를
//   제대로 뽑는지 확인
// -------------------------------------------
module tb_decoder;

    // DUT 구동용 신호
    reg        clk;
    reg        reset;
    reg        ena;           // 1일 때 PC/decoder 동작

    // ROM / Decoder 관찰 신호
    wire [3:0] pc;            // 현재 PC
    wire [7:0] instr;         // ROM에서 읽은 명령어

    wire [2:0] alu_opcode;    // ALU 연산 종류
    wire       dst_sel;       // 0=R0, 1=R1
    wire [3:0] imm4;          // 즉시값
    wire       alu_enable;    // ALU 사용 여부
    wire       write_enable;  // 레지스터 갱신 여부
    wire       use_imm;       // WB에서 imm 사용 여부

  

    //========================
    // DUT 인스턴스들
    //========================

    // PC: 0~7까지 증가 후 다시 0으로 롤오버
    pc #(
        .WIDTH(4),
        .LAST (4'd7)
    ) u_pc (
        .clk  (clk),
        .reset(reset),
        .ena  (ena),
        .pc   (pc)
    );

    // ROM: PC를 주소로 사용
    prog_rom u_progrom (
        .addr (pc),
        .instr(instr)
    );

    // Decoder: instr를 제어신호로 변환
    decoder u_decoder (
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
    // 클럭 생성 (10ns 주기)
    //========================
    always #5 clk = ~clk;

    //========================
    // 테스트 시퀀스
    //========================
    initial begin
        // 초기 상태: 리셋 ON, 동작 정지
        clk   = 1'b0;
        reset = 1'b1;
        ena   = 1'b0;

        // 파형 덤프 (원하면 사용)
        $dumpfile("tb_decoder.vcd");
        $dumpvars(0, tb_decoder);

        // 1) 파워온 리셋 구간
        #20;
        reset = 1'b0;   // 리셋 해제
        ena   = 1'b1;   // CPU 동작 시작

        // 2) 정상 동작 구간 (PC가 한 바퀴 이상 돌도록)
        #120;

        // 3) 중간에 다시 리셋 걸어보기
        reset = 1'b1;
        #20;
        reset = 1'b0;

        // 4) ena 끄고 / 켜서 정지/재개 확인
        #40;
        ena = 1'b0;     // PC/decoder 정지
        #40;
        ena = 1'b1;     // 다시 동작 시작

        #100;
        $finish;
    end

    //========================
    // 모니터링 로그 출력
    //========================
    initial begin
        $display(" time | rst ena | pc instr  | opc dst imm | alu_en we use_imm");
        $display("--------------------------------------------------------------");
        $monitor("%4t |  %b    %b |  %1d  %08b | %03b   %b   %1d  |   %b     %b    %b",
                 $time, reset, ena,
                 pc, instr,
                 alu_opcode, dst_sel, imm4,
                 alu_enable, write_enable, use_imm);
    end

endmodule
