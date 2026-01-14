// pc.v
// Program Counter
// - WIDTH 비트 너비의 PC 카운터
// - 0 ~ LAST 까지 증가 후 다시 0으로 돌아가는 구조
// - reset: PC를 0으로 초기화
// - ena: 1일 때에만 PC 값 증가

`default_nettype none
module pc #(
    parameter WIDTH = 4,           // PC 비트 폭 (기본 4bit)
    parameter LAST  = 4'd7         // PC가 도달할 마지막 주소
)(                                 // 0 ~ LAST 까지 사용
    input  wire              clk,  // 시스템 클럭
    input  wire              reset,// 비동기 리셋(1이면 PC 즉시 0)
    input  wire              ena,  // PC enable (1일 때만 카운트)
    output reg  [WIDTH-1:0]  pc    // 현재 PC 값(ROM 주소로 사용)
);

    // 클럭 상승엣지 또는 reset 상승엣지에서 동작
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            // reset=1이면 PC를 0으로 초기화
            pc <= {WIDTH{1'b0}};          // 예: WIDTH=4 -> 4'b0000
        end else if (ena) begin
            // ena=1일 때만 PC 값 갱신
            if (pc == LAST)
                // 마지막 주소에 도달하면 다시 0으로
                pc <= {WIDTH{1'b0}};
            else
                // 그 외에는 1씩 증가
                pc <= pc + 1'b1;
        end
        // ena=0이면 PC 유지
    end

endmodule



`timescale 1ns/1ps
`define default_netname none



