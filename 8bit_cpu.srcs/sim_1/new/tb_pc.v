module tb_pc;

    // DUT 포트 대응 신호
    reg        clk;
    reg        reset;
    reg        ena;
    wire [3:0] pc;   // WIDTH=4 기준

    // DUT 인스턴스
    pc #(
        .WIDTH(4),
        .LAST (4'd7)   // 0~7까지 증가 후 다시 0
    ) u_pc (
        .clk  (clk),
        .reset(reset),
        .ena  (ena),
        .pc   (pc)
    );

    // 10ns 주기의 클럭 생성 (100MHz 느낌)
    always #5 clk = ~clk;

    // 테스트 시퀀스
    initial begin
        // 초기값 설정
        clk   = 1'b0;
        reset = 1'b1;
        ena   = 1'b0;


        // 리셋 유지
        #20;
        reset = 1'b0;

        // 1) ena=1로 PC 증가 확인 (0→1→2→...→7→0 롤오버까지)
        ena = 1'b1;
        #200;   // 충분히 여러 클럭 돌리기

        // 2) ena=0일 때 값 유지되는지 확인
        ena = 1'b0;
        #50;

        // 3) 다시 ena=1로 켜서 이어서 증가하는지 확인
        ena = 1'b1;
        #80;

        $finish;
    end

    // 모니터링: 시뮬레이션 로그로 상태 출력
    initial begin
        $display("                time | reset ena | pc");
        $monitor("%t |   %b     %b | %d", $time, reset, ena, pc);
    end

endmodule
