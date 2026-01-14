// regfile.v
// 8bit 레지스터 2개(R0, R1)로 구성된 간단한 레지스터 파일
//
// 역할:
// - CPU에서 사용하는 일반 레지스터 R0, R1 저장
// - write_enable이 1일 때, dst_sel에 따라 R0 또는 R1에 data_in을 기록
// - reset 시 R0, R1 모두 0으로 초기화
//
// 제어 신호:
// - ena          : 전체 CPU enable (1일 때만 쓰기 동작 허용)
// - write_enable : 이 사이클에 레지스터를 갱신할지 여부
// - dst_sel      : 어느 레지스터에 쓸지 선택 (0 = R0, 1 = R1)

`default_nettype none
module regfile (
    input  wire       clk,           // 시스템 클럭
    input  wire       reset,         // 비동기 리셋
    input  wire       ena,           // CPU enable (1일 때만 동작)
    input  wire       write_enable,  // 레지스터 쓰기 활성화
    input  wire       dst_sel,       // 목적 레지스터 선택 (0=R0, 1=R1)
    input  wire [7:0] data_in,       // WB 데이터 (ALU 결과 또는 imm4 확장)

    output reg  [7:0] R0,            // 레지스터 0
    output reg  [7:0] R1             // 레지스터 1
);

    // 동기식 레지스터 갱신 블록
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            // 리셋 시 R0, R1 모두 0으로 초기화
            R0 <= 8'd0;
            R1 <= 8'd0;
        end else if (ena && write_enable) begin
            // ena=1 이고 write_enable=1일 때만 실제 쓰기 동작 수행
            if (!dst_sel)
                // dst_sel=0 → R0에 data_in 저장
                R0 <= data_in;
            else
                // dst_sel=1 → R1에 data_in 저장
                R1 <= data_in;
        end
        // ena=0 이거나 write_enable=0이면 R0, R1 유지
    end

endmodule

