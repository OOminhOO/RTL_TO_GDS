`default_nettype none

module uart_tx #(
    parameter CLK_FREQ  = 100_000_000, // Basys3 100MHz
     parameter BAUD_RATE = 9_600        // ? 9600으로 변경
)(
    input  wire clk,
    input  wire reset,
    input  wire start,        // 1클럭 high → data_in 전송 시작
    input  wire [7:0] data_in,
    output reg  tx,           // UART TX 라인
    output reg  busy          // 전송 중이면 1
);
    localparam integer CLKS_PER_BIT = CLK_FREQ / BAUD_RATE;

    reg [15:0] clk_cnt;
    reg [3:0]  bit_idx;
    reg [9:0]  shift_reg;  // start(0) + data[7:0] + stop(1)

    localparam S_IDLE  = 2'd0;
    localparam S_START = 2'd1;
    localparam S_DATA  = 2'd2;
    localparam S_STOP  = 2'd3;

    reg [1:0] state;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state     <= S_IDLE;
            tx        <= 1'b1;    // idle high
            busy      <= 1'b0;
            clk_cnt   <= 0;
            bit_idx   <= 0;
            shift_reg <= 10'b1111111111;
        end else begin
            case (state)
                S_IDLE: begin
                    tx      <= 1'b1;
                    busy    <= 1'b0;
                    clk_cnt <= 0;
                    bit_idx <= 0;
                    if (start) begin
                        // start + data + stop 준비
                        shift_reg <= {1'b1, data_in, 1'b0}; // LSB부터 나감
                        busy      <= 1'b1;
                        state     <= S_START;
                    end
                end
                S_START,
                S_DATA,
                S_STOP: begin
                    if (clk_cnt == CLKS_PER_BIT-1) begin
                        clk_cnt <= 0;
                        tx      <= shift_reg[0];         // LSB 출력
                        shift_reg <= {1'b1, shift_reg[9:1]}; // 오른쪽 시프트

                        if (bit_idx == 4'd9) begin
                            state   <= S_IDLE;
                            busy    <= 1'b0;
                            bit_idx <= 0;
                        end else begin
                            bit_idx <= bit_idx + 1'b1;
                        end
                    end else begin
                        clk_cnt <= clk_cnt + 1'b1;
                    end
                end
            endcase
        end
    end

endmodule


`default_nettype none

module uart_rx #(
    parameter CLK_FREQ  = 100_000_000,
     parameter BAUD_RATE = 9_600      // ? 9600
)(
    input  wire clk,
    input  wire reset,
    input  wire rx,          // UART RX 라인
    output reg  [7:0] data_out,
    output reg  data_valid   // 새 바이트 1클럭 동안 1
);
    localparam integer CLKS_PER_BIT = CLK_FREQ / BAUD_RATE;

    localparam S_IDLE   = 3'd0;
    localparam S_START  = 3'd1;
    localparam S_DATA   = 3'd2;
    localparam S_STOP   = 3'd3;

    reg [2:0]  state;
    reg [15:0] clk_cnt;
    reg [2:0]  bit_idx;
    reg [7:0]  rx_shift;
    reg        rx_sync1, rx_sync2;

    // RX 동기화
    always @(posedge clk) begin
        rx_sync1 <= rx;
        rx_sync2 <= rx_sync1;
    end

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state      <= S_IDLE;
            clk_cnt    <= 0;
            bit_idx    <= 0;
            rx_shift   <= 0;
            data_out   <= 0;
            data_valid <= 1'b0;
        end else begin
            data_valid <= 1'b0; // 기본 0
            case (state)
                S_IDLE: begin
                    if (rx_sync2 == 1'b0) begin // start bit 감지
                        state   <= S_START;
                        clk_cnt <= 0;
                    end
                end
                S_START: begin
                    if (clk_cnt == (CLKS_PER_BIT/2)) begin
                        // start 비트 중간 샘플링
                        if (rx_sync2 == 1'b0) begin
                            clk_cnt <= 0;
                            bit_idx <= 0;
                            state   <= S_DATA;
                        end else begin
                            state <= S_IDLE; // 노이즈
                        end
                    end else begin
                        clk_cnt <= clk_cnt + 1'b1;
                    end
                end
                S_DATA: begin
                    if (clk_cnt == CLKS_PER_BIT-1) begin
                        clk_cnt       <= 0;
                        rx_shift[bit_idx] <= rx_sync2;
                        if (bit_idx == 3'd7) begin
                            bit_idx <= 0;
                            state   <= S_STOP;
                        end else begin
                            bit_idx <= bit_idx + 1'b1;
                        end
                    end else begin
                        clk_cnt <= clk_cnt + 1'b1;
                    end
                end
                S_STOP: begin
                    if (clk_cnt == CLKS_PER_BIT-1) begin
                        clk_cnt    <= 0;
                        data_out   <= rx_shift;
                        data_valid <= 1'b1;
                        state      <= S_IDLE;
                    end else begin
                        clk_cnt <= clk_cnt + 1'b1;
                    end
                end
            endcase
        end
    end

endmodule

