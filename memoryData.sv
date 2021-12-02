`default_nettype none

module memoryData (
  clk,
  rst,
  read_addr,
  read_data,
  write_addr,
  write_data,
  write_enable
);

  input wire clk, rst;
  input wire [31:0] read_addr, write_addr, write_data;
  input wire write_enable;
  output reg [31:0] read_data;

  (* ram_style = "block" *)
  logic [31:0] mem [4095:0];

  task init_mem;
    begin
      for(int i=0; i<4096; i++) begin
        mem[i] <= 32'd0;
      end
    end
  endtask

  initial begin
    init_mem();
  end

  always_ff @(posedge clk) begin
    if(rst) begin
      init_mem();
    end else begin
      // read
      read_data <= mem[read_addr[8:2]];
      // write
      if(write_enable) begin
       mem[write_addr[8:2]] <= write_data;
      end
    end
  end

endmodule

`default_nettype wire