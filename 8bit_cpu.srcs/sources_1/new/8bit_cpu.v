// cpu_core_fpga.v
// -------------------------------------------
// 8-bit 미니 CPU + UART TX + 스위치 ALU 모드
//  - sw_mode = 0 : ROM 기반 CPU 모드
//  - sw_mode = 1 : 스위치 기반 ALU 테스트 모드
//  - sw_ena  = 1 : 전체 CPU 동작 (PC/디코더/레지스터/ALU)
//  - sw_ena  = 0 : 전체 정지 (PC hold, 레지스터 hold)
// -------------------------------------------
`define default_netname none
module cpu_core_fpga (
    input  wire       clk,
    input  wire       reset,
    
    input  wire       sw_ena,      // 전체 CPU enable (1: 동작, 0: 정지)
    input  wire       sw_mode,     // 0: CPU mode, 1: switch(ALU test) mode
    
    input  wire [2:0] sw_opcode,   // 스위치 모드용 ALU opcode
    input  wire [3:0] sw_a,        // 스위치 모드용 operand A (하위 4비트)
    input  wire [3:0] sw_b,        // 스위치 모드용 operand B (하위 4비트)
    
    input  wire       send_btn,    // UART TX 트리거 버튼
    
    output wire [15:0] led,        // 디버깅/상태 표시용 LED
    // input  wire uart_rx,        // (미사용)
    output wire       uart_tx      // UART TX 출력
);
    // ====================================================
    // 0. 내부 디버그 신호 (현재는 외부 포트로는 안 빼는 상태)
    // ====================================================
    wire [3:0] pc_dbg;
    wire [7:0] R0_dbg;
    wire [7:0] R1_dbg;
    wire [7:0] alu_result_dbg;

    // ====================================================
    // 1. 전역 enable
    //    - sw_ena = 1: PC/decoder/regfile/ALU 동작
    //    - sw_ena = 0: 모두 hold (PC 증가 X, 레지스터 write X)
    // ====================================================
    wire ena = sw_ena;

    // ====================================================
    // 2. PC + ROM
    //    - PC: 4비트, 0~LAST까지 순환
    //    - ROM: pc를 주소로 1바이트 명령어 출력
    // ====================================================
    wire [3:0] pc;

    pc #(
        .WIDTH(4),
        .LAST (4'd7)   // rom[0..7]까지만 사용
    ) u_pc (
        .clk  (clk),
        .reset(reset),
        .ena  (ena),   // sw_ena=1인 동안 계속 PC 증가
        .pc   (pc)
    );

    wire [7:0] instr;

    prog_rom u_rom (
        .addr (pc),
        .instr(instr)
    );

    // ====================================================
    // 3. DECODER
    //    - ROM에서 읽은 instr를 해석해서 ALU/레지스터 제어 신호 생성
    //    - ena=0이면 내부 상태 hold (명령 해석 중단)
    // ====================================================
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

    // ====================================================
    // 4. REGFILE (R0, R1)
    //    - CPU 모드: 디코더에서 넘어온 write_enable 사용
    //    - 스위치 모드: reg_we를 0으로 막아서 R0/R1 고정
    // ====================================================
    wire [7:0] R0;
    wire [7:0] R1;
    
    // 스위치 모드에서는 레지스터 파일 write 금지
    wire reg_we = sw_mode ? 1'b0 : write_enable;

    // write-back 데이터 선택
    //  - use_imm=1: zero-extend된 imm4
    //  - use_imm=0: ALU 결과
    wire [7:0] wb_data =
        use_imm
            ? {4'b0000, imm4}
            : alu_result_dbg;

    regfile u_reg (
        .clk         (clk),
        .reset       (reset),
        .ena         (ena),      // 전역 CPU enable
        .write_enable(reg_we),
        .dst_sel     (dst_sel),
        .data_in     (wb_data),
        .R0          (R0),
        .R1          (R1)
    );

    // ====================================================
    // 5. ALU 입력/제어 선택
    //    - CPU 모드 : R0/R1 + decoder의 alu_opcode 사용
    //    - 스위치 모드: sw_a/sw_b + sw_opcode 사용 (R0/R1 write 없음)
    // ====================================================
    // 스위치 모드에서 사용할 8비트 operand (상위 4비트 0 확장)
    wire [7:0] alu_sw_a = {4'b0000, sw_a};
    wire [7:0] alu_sw_b = {4'b0000, sw_b};

    // A, B 선택
    wire [7:0] alu_a = sw_mode ? alu_sw_a : R0;
    wire [7:0] alu_b = sw_mode ? alu_sw_b : R1;

    // opcode 선택
    wire [2:0] alu_op = sw_mode ? sw_opcode : alu_opcode;

    // enable 선택
    //  - 스위치 모드 : 전역 ena만으로 on/off
    //  - CPU 모드    : 디코더의 alu_enable 사용
    wire alu_en =
        (sw_mode == 1'b1) ? ena         // switch mode
                          : alu_enable; // cpu mode

    // ALU
    alu u_alu (
        .a     (alu_a),
        .b     (alu_b),
        .opcode(alu_op),
        .ena   (alu_en),
        .result(alu_result_dbg)
    ); 

    // ====================================================
    // 6. UART TX
    //    - send_btn을 눌렀을 때 현재 ALU 결과(1바이트) 전송
    //    - 버튼 입력은 비동기이므로 2FF 동기화 후 상승엣지 검출
    //    - busy=1(전송 중)일 때 들어온 버튼은 무시
    // ====================================================
    wire uart_tx_start;
    wire uart_tx_busy;

    // 버튼 동기화 플립플롭
    reg send_btn_sync_0;
    reg send_btn_sync_1;
    reg send_btn_sync_1_d;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            send_btn_sync_0   <= 1'b0;
            send_btn_sync_1   <= 1'b0;
            send_btn_sync_1_d <= 1'b0;
        end else begin
            send_btn_sync_0   <= send_btn;
            send_btn_sync_1   <= send_btn_sync_0;
            send_btn_sync_1_d <= send_btn_sync_1;
        end
    end

    // 상승엣지 검출
    wire send_pulse = send_btn_sync_1 & ~send_btn_sync_1_d;

    // busy일 땐 무시, idle일 때만 start
    assign uart_tx_start = send_pulse & ~uart_tx_busy;
    
    uart_tx #(
        .CLK_FREQ (100_000_000),
        .BAUD_RATE(9600)
    ) u_uart_tx (
        .clk    (clk),
        .reset  (reset),
        .start  (uart_tx_start),
        .data_in(alu_result_dbg),   // 현재 ALU 결과 1바이트 전송
        .tx     (uart_tx),
        .busy   (uart_tx_busy)
    );

    // ====================================================
    // 7. LED 출력 매핑 (디버깅용)
    //    led[7:0]   : ALU 결과
    //    led[15:13] : sw_opcode (스위치 모드에서 ALU 코드 확인용)
    //    led[12]    : sw_mode   (0=CPU, 1=SWITCH)
    //    led[11]    : sw_ena    (전체 enable 상태)
    //    led[10:8]  : 현재는 미사용(0)
    // ====================================================
    assign led[7:0]   = alu_result_dbg;
    assign led[15:13] = sw_opcode;
    assign led[11]    = sw_ena;
    assign led[12]    = sw_mode;
    assign led[10:8]  = 3'b000;

    // 내부 디버깅용 와이어 (필요하면 나중에 포트로 뽑아서 확인)
    assign pc_dbg = pc;
    assign R0_dbg = R0;
    assign R1_dbg = R1;

endmodule
