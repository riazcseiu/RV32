`default_nettype none

module memoryInstruction (
  clk,
  rst,
  addr,
  inst
);

  input wire clk, rst;
  input wire [31:0] addr;
  output reg [31:0] inst;

  (* ram_style = "block" *)
  reg [31:0] mem [63:0];

  initial begin
    $readmemh("xxx.hex", mem);
  end

  always_ff @(posedge clk) begin
    if(!rst) begin
      inst <= mem[addr[7:2]];
    end
  end

endmodule

`default_nettype wire
