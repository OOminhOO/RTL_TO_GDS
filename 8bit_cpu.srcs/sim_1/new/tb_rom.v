

module tb_progrom;

  reg [3:0] addr;   // PC에서 들어오는 주소 (0~15)
  wire  [7:0] instr;   // 해당 주소의 명령어 출력
  integer i;
    
    
    prog_rom u_progrom (
        .addr(addr), 
        .instr(instr)
    );
    
    initial begin
    addr = 0;
    #10;
     for (i = 0; i < 10; i = i + 1) begin
           addr = i; 
        #10;
     end
     #20;
     addr = 4;
     #10;
     addr = 2;
     #10;
     addr = 0;
     #10; 
     $finish;
    end
endmodule

