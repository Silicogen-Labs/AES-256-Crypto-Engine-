//////////////////////////////////////////////////////////////////////////////
// Module: aes_top
// Description: AES-256 Top Level Module
//              Iterative architecture with 2-state FSM
//              Supports both encryption and decryption
//
// Latency: 17 cycles (1 load + 8 key expansion + 14 rounds + 1 output)
//
// Author: SilicogenAI
// Date: 2026-03-10
//////////////////////////////////////////////////////////////////////////////

module aes_top (
    input              clk,
    input              rst_n,
    input              start,
    input              mode,        // 0 = encrypt, 1 = decrypt
    input      [255:0] key,
    input      [127:0] data_in,
    output reg [127:0] data_out,
    output reg         valid,
    output             busy
);

    // FSM states
    localparam IDLE = 2'b00;
    localparam KEY_EXP = 2'b01;
    localparam PROCESS = 2'b10;
    localparam DONE = 2'b11;

    // Registers
    reg [1:0]  state;
    reg [3:0]  round_cnt;          // 0-14 for rounds
    reg [127:0] state_reg;         // AES state
    reg [255:0] key_reg;           // Input key
    reg         mode_reg;          // Latched mode
    reg [1919:0] round_keys;       // 15 round keys

    // Key expansion signals
    wire        key_exp_done;
    wire [1919:0] key_exp_round_keys;
    reg         key_exp_start;

    // Round signals
    wire [127:0] round_out;
    wire [127:0] inv_round_out;
    wire [127:0] round_key;
    wire [3:0]   round_key_idx;

    // FSM state register
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            round_cnt <= 4'd0;
            state_reg <= 128'd0;
            key_reg <= 256'd0;
            mode_reg <= 1'b0;
            data_out <= 128'd0;
            valid <= 1'b0;
            key_exp_start <= 1'b0;
            round_keys <= 1920'd0;
        end else begin
            valid <= 1'b0;  // Default
            key_exp_start <= 1'b0;  // Default

            case (state)
                IDLE: begin
                    if (start) begin
                        // Load inputs
                        key_reg <= key;
                        state_reg <= data_in;
                        mode_reg <= mode;
                        round_cnt <= 4'd0;
                        key_exp_start <= 1'b1;
                        state <= KEY_EXP;
                    end
                end

                KEY_EXP: begin
                    if (key_exp_done) begin
                        // Key expansion complete, store round keys
                        round_keys <= key_exp_round_keys;
                        // Do initial AddRoundKey (round 0)
                        // For encrypt: use round_key[0], for decrypt: use round_key[14]
                        state_reg <= mode_reg ? 
                            (state_reg ^ key_exp_round_keys[1919:1792]) : // decrypt: round_key[14]
                            (state_reg ^ key_exp_round_keys[127:0]);      // encrypt: round_key[0]
                        // Start full rounds from round 1 (round 0 was initial ARK)
                        round_cnt <= 4'd1;
                        state <= PROCESS;
                    end
                end

                PROCESS: begin
                    if (round_cnt == 4'd14) begin
                        // Final round complete
                        state_reg <= mode_reg ? inv_round_out : round_out;
                        state <= DONE;
                    end else begin
                        // Continue to next round
                        state_reg <= mode_reg ? inv_round_out : round_out;
                        round_cnt <= round_cnt + 4'd1;
                    end
                end

                DONE: begin
                    // Output result
                    data_out <= state_reg;
                    valid <= 1'b1;
                    state <= IDLE;
                end

                default: state <= IDLE;
            endcase
        end
    end

    assign busy = (state != IDLE);

    // Key expansion instance
    aes_key_expansion key_exp_inst (
        .clk(clk),
        .rst_n(rst_n),
        .start(key_exp_start),
        .key_in(key_reg),
        .done(key_exp_done),
        .round_keys(key_exp_round_keys)
    );

    // Round key selection
    // For encryption: round_key[round_cnt]
    // For decryption: round_key[14 - round_cnt]
    assign round_key_idx = mode_reg ? (4'd14 - round_cnt) : round_cnt;
    assign round_key = round_keys[(round_key_idx * 128) +: 128];

    // Encryption round instance
    aes_round enc_round_inst (
        .state_in(state_reg),
        .round_key(round_key),
        .is_final(round_cnt == 4'd14),
        .state_out(round_out)
    );

    // Decryption round instance
    aes_inv_round dec_round_inst (
        .state_in(state_reg),
        .round_key(round_key),
        .is_final(round_cnt == 4'd14),
        .state_out(inv_round_out)
    );

endmodule
