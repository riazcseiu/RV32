`default_nettype none

module instructionDecode(
    inst,
    rs1,
    rs2,
    rd,
    imm,
    funct3,
    funct7,
    arithmetic,
    arithmetic_imm,
    load,
    store,
    branch,
    jal,
    jalr,
    lui,
    auipc
);

    input wire [31:0] inst;
    output wire [4:0] rs1, rs2, rd;
    output logic [31:0] imm;    // wire
    output wire [2:0] funct3;
    output wire [6:0] funct7;
    output wire arithmetic, arithmetic_imm, load, store, branch, jal, jalr, lui, auipc;

    wire [6:0] opcode = inst[6:0];

    wire r_type = (opcode == 7'b0110011);
    wire i_type = (opcode == 7'b0000011) || (opcode == 7'b0010011) || (opcode == 7'b1100111);
    wire s_type = (opcode == 7'b0100011);
    wire b_type = (opcode == 7'b1100011);
    wire j_type = (opcode == 7'b1101111);
    wire u_type = (opcode == 7'b0110111) || (opcode == 7'b0010111);

    assign rs1 = (r_type | i_type | s_type | b_type) ? inst[19:15] : 5'd0;
    assign rs2 = (r_type | s_type | b_type) ? inst[24:20] : 5'd0;
    assign rd  = (r_type | i_type | j_type | u_type) ? inst[11:7] : 5'd0;

    always_comb begin
        if      (i_type) imm = {{20{inst[31]}}, inst[31:20]};
        else if (s_type) imm = {{20{inst[31]}}, inst[31:25], inst[11:7]};
        else if (b_type) imm = {{20{inst[31]}}, inst[7], inst[30:25], inst[11:8], 1'd0};
        else if (j_type) imm = {{12{inst[31]}}, inst[19:12], inst[20], inst[30:21], 1'd0};
        else if (u_type) imm = {inst[31:12], 12'd0};
        else imm = 32'd0;
    end

    assign funct3 = inst[14:12];
    assign funct7 = (inst[6:0] == 7'b011011) ? inst[31:25] : 7'd0;

    assign arithmetic     	= (opcode == 7'b0110011) ? 1'd1 : 1'd0;
    assign arithmetic_imm 	= (opcode == 7'b0010011) ? 1'd1 : 1'd0;
    assign load   			= (opcode == 7'b0000011) ? 1'd1 : 1'd0;
    assign store  			= (opcode == 7'b0100011) ? 1'd1 : 1'd0;
    assign branch 			= (opcode == 7'b1100011) ? 1'd1 : 1'd0;
    assign jal    			= (opcode == 7'b1101111) ? 1'd1 : 1'd0;
    assign jalr   			= (opcode == 7'b1100111) ? 1'd1 : 1'd0;
    assign lui    			= (opcode == 7'b0110111) ? 1'd1 : 1'd0;
    assign auipc  			= (opcode == 7'b0010111) ? 1'd1 : 1'd0;

endmodule

`default_nettype wire