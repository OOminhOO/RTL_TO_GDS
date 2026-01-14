module top_gds (
    input  wire       clk,
    input  wire       reset,
    output wire [3:0] PC,
    output wire [7:0] DOUT
);
    cpu_core_gds u_core (
        .clk    (clk),
        .reset  (reset),
        .ena    (1'b1),      // 항상 동작하게
        .pc_out (PC),
        .r0_out (DOUT),
        .r1_out (),          // 안 쓰면 묶지 않아도 됨 (또는 open)
        .alu_out()
    );
endmodule