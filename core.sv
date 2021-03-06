`default_nettype none

module core(
  clk,
  rst,
  led,
  data_seg
);

  input wire clk, rst;
  output wire [15:0] led;
  output wire [15:0] data_seg;

  // Program counter
  reg [31:0] pc;

  // Initialize pc
  task init_pc;
    begin
      pc <= 32'd0;
    end
  endtask

  // Update led
  assign led = pc[15:0];

  // State
  reg state_idle, state_if, state_de, state_ex, state_ma, state_wb;

  // Initialize state
  task init_state;
    begin
      state_idle <= 7'd1;
      {state_if, state_de, state_ex, state_ma, state_wb} <= 7'd0;
    end
  endtask

  // FSM
  always_ff @(posedge clk) begin
    if(rst) begin
      init_state();
    end
    else begin
      if(state_idle) begin
        state_idle <= 1'b0;
        state_if <= 1'b1;
      end
      else if(state_if) begin
        state_if <= 1'b0;
        state_de <= 1'b1;
      end
      else if(state_de) begin
        state_de <= 1'b0;
        state_ex <= 1'b1;
      end
      else if(state_ex) begin
        state_ex <= 1'b0;
        state_ma <= 1'b1;
      end
      else if(state_ma) begin
        state_ma <= 1'b0;
        state_wb <= 1'b1;
      end
      else begin
        state_wb <= 1'b0;
        state_if <= 1'b1;
      end
    end
  end

  // Instruction Fetch

  // Instruction memory
  typedef struct {
    logic [31:0]  addr; // wire
    reg [31:0]    inst;
  } instruction_memory;

  instruction_memory imem;

  assign imem.addr = pc;

  memoryInstruction Imem (
    .clk(clk),
    .rst(rst),

    .addr(imem.addr),
    .inst(imem.inst)
  );

  // Instruction Decode

  typedef struct {
    logic [4:0]   rs1, rs2;   // wire
    logic [4:0]   rd;         // wire
    logic [2:0]   funct3;     // wire
    logic [6:0]   funct7;     // wire
    logic [31:0]  imm;        // wire
    logic _arithmetic, _arithmetic_imm, _load, _store, _branch, _jal, _jalr, _lui, _auipc; // wire
  } instruction_decode;

  instruction_decode de;

  instructionDecode Decode (
    .inst(imem.inst),

    .rs1(de.rs1),
    .rs2(de.rs2),
    .rd(de.rd),

    .funct3(de.funct3),
    .funct7(de.funct7),

    .imm(de.imm),

    .arithmetic(de._arithmetic),
    .arithmetic_imm(de._arithmetic_imm),
    .load(de._load),
    .store(de._store),
    .branch(de._branch),
    .jal(de._jal),
    .jalr(de._jalr),
    .lui(de._lui),
    .auipc(de._auipc)
  );

  typedef struct {
    logic [31:0] rs1_data, rs2_data; // wire
    logic [31:0] rd_data; // wire
  } register_file;

  register_file rf;

  // Register
  reg [31:0] register [31:0];

  task init_rf;
    begin
      for(int i=0; i<32; i++) begin
        register[i] <= 32'd0;
      end
    end
  endtask

  assign rf.rs1_data = (de.rs1 == 5'd0) ? 32'd0 : register[de.rs1];
  assign rf.rs2_data = (de.rs2 == 5'd0) ? 32'd0 : register[de.rs2];
  assign data_seg = pc[15:0];

  always_ff @(posedge clk) begin
    if(rst) begin
      init_rf();
    end
    else if(state_wb) begin
      register[de.rd] <= rf.rd_data;
    end
  end

  logic [31:0] alu_out; // wire

  // Execution
  alu Alu (
    .rs1_data(rf.rs1_data),
    .rs2_data(rf.rs2_data),

    .imm_data(de.imm),

    .funct3(de.funct3),
    .funct7(de.funct7),

    .arithmetic(de._arithmetic),
    .arithmetic_imm(de._arithmetic_imm),
    .load(de._load),
    .store(de._store),
    .branch(de._branch),

    .alu_out(alu_out)
  );


  // Memory Access

  typedef struct {
    logic [31:0] read_addr, read_data, write_addr, write_data; // read_addr, write_addr, write_data ... wire
    logic write_enable;
  } data_memory;

  data_memory dmem;

  assign dmem.read_addr = alu_out;
  assign dmem.write_addr = alu_out;
  assign dmem.write_data = (de.funct3 == 3'b000) ? rf.rs2_data[7:0] :
                           (de.funct3 == 3'b001) ? rf.rs2_data[15:0] :
                           rf.rs2_data;
  assign dmem.write_enable = state_ma && de._store;

  memoryData Dmem (
    .clk(clk),
    .rst(rst),

    .read_addr(dmem.read_addr),
    .read_data(dmem.read_data),

    .write_addr(dmem.write_addr),
    .write_data(dmem.write_data),
    .write_enable(dmem.write_enable)
  );


  // Write back

  always_comb begin
    if(de._jal || de._jalr) begin
      rf.rd_data = pc + 32'd4;
    end
    else if(de._load) begin
      rf.rd_data = dmem.read_data;
    end
    else if(de._lui) begin
      rf.rd_data = de.imm;
    end
    else if(de._auipc) begin
      rf.rd_data = pc + de.imm;
    end
    else begin
      rf.rd_data = alu_out;
    end
  end

  // Update pc
  always_ff @(posedge clk) begin
    if(rst) begin
      init_pc();
    end
    else begin
      if(state_wb) begin
        if(de._branch) begin
          if(alu_out) pc <= pc + de.imm;
          else pc <= pc + 32'd4;
        end
        else if(de._jal) begin
          pc <= pc + de.imm;
        end
        else if(de._jalr) begin
          pc <= rf.rs1_data + de.imm;
        end
        else if(de._lui) begin
          pc <= pc + 32'd4;
        end
        else if(de._auipc) begin
          pc <= pc + 32'd4;
        end
        else begin
          pc <= pc + 32'd4;
        end
      end
    end
  end

  // Initialize
  initial begin
    init_pc();
    init_state();
    init_rf();
  end

endmodule

`default_nettype wire