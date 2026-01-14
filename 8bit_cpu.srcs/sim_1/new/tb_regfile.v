`timescale 1ns/1ps
`define default_netname none

// tb_regfile.v
// -----------------------------------------
// regfile 단위 테스트벤치
// - reset 시 R0,R1이 0으로 초기화되는지
// - ena=1, write_enable=1일 때만 값이 써지는지
// - dst_sel=0 → R0, dst_sel=1 → R1에 쓰이는지
// - write_enable=0 / ena=0일 때는 값이 유지되는지
// -----------------------------------------
module tb_regfile;

    // 입력 신호
    reg        clk;
    reg        reset;
    reg        ena;
    reg        write_enable;
    reg        dst_sel;        // 0=R0, 1=R1
    reg  [7:0] data_in;

    // 출력 신호
    wire [7:0] R0;
    wire [7:0] R1;

    // DUT 인스턴스
    regfile u_regfile (
        .clk         (clk),
        .reset       (reset),
        .ena         (ena),
        .write_enable(write_enable),
        .dst_sel     (dst_sel),
        .data_in     (data_in),
        .R0          (R0),
        .R1          (R1)
    );

    // 10ns 주기의 클럭 생성
    always #5 clk = ~clk;

    // 테스트 시퀀스
    initial begin
        // 초기 상태
        clk          = 1'b0;
        reset        = 1'b1;
        ena          = 1'b0;
        write_enable = 1'b0;
        dst_sel      = 1'b0;
        data_in      = 8'd0;



        // 1) 리셋 구간: R0,R1이 0으로 초기화되는지 확인
        #20;
        reset = 1'b0;    // 리셋 해제

        // 2) ena=1, write_enable=1, dst_sel=0 → R0에 쓰기
        ena          = 1'b1;
        write_enable = 1'b1;
        dst_sel      = 1'b0;   // R0 선택
        data_in      = 8'd10;
        #10;   // 한 클럭 정도 기다림

        // 3) 같은 조건에서 dst_sel=1 → R1에 쓰기
        dst_sel = 1'b1;        // R1 선택
        data_in = 8'd20;
        #10;

        // 4) write_enable=0 → 값이 안 써져야 함
        write_enable = 1'b0;
        data_in      = 8'd99;  // 무시되어야 함
        #10;

        // 5) ena=0 → 값이 안 써져야 함 (enable off)
        ena          = 1'b0;
        write_enable = 1'b1;
        dst_sel      = 1'b0;
        data_in      = 8'd30;  // R0에 안 써져야 함
        #10;

        // 6) 다시 ena=1 → 쓰기 재개
        ena          = 1'b1;
        write_enable = 1'b1;
        dst_sel      = 1'b0;
        data_in      = 8'd40;  // 이제는 R0=40으로 바뀌어야 함
        #10;

        // 7) 마지막으로 리셋 한 번 더
        reset = 1'b1;
        #10;
        reset = 1'b0;
        #10;

        $finish;
    end

    // 모니터링: 상태를 로그로 출력
    initial begin
        $display(" time | rst ena we dst | data_in | R0  R1");
        $display("------------------------------------------");
        $monitor("%4t |  %b   %b   %b  %b  |  %3d    | %3d %3d",
                 $time, reset, ena, write_enable, dst_sel,
                 data_in, R0, R1);
    end

endmodule
