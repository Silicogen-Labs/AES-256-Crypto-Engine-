//////////////////////////////////////////////////////////////////////////////
// Module: aes_round
// Description: Single AES encryption round
//              Combines SubBytes, ShiftRows, MixColumns, and AddRoundKey
//
// Author: SilicogenAI
// Date: 2026-03-10
//////////////////////////////////////////////////////////////////////////////

module aes_round (
    input  [127:0] state_in,
    input  [127:0] round_key,
    input          is_final,      // 1 = final round (no MixColumns)
    output [127:0] state_out
);

    // Internal signals
    wire [127:0] sub_bytes_out;
    wire [127:0] shift_rows_out;
    wire [127:0] mix_columns_out;
    wire [127:0] add_round_key_out;

    // SubBytes - 16 parallel S-Box lookups
    aes_sbox sbox_0  (.data_in(state_in[127:120]), .data_out(sub_bytes_out[127:120]));
    aes_sbox sbox_1  (.data_in(state_in[119:112]), .data_out(sub_bytes_out[119:112]));
    aes_sbox sbox_2  (.data_in(state_in[111:104]), .data_out(sub_bytes_out[111:104]));
    aes_sbox sbox_3  (.data_in(state_in[103:96]),  .data_out(sub_bytes_out[103:96]));
    aes_sbox sbox_4  (.data_in(state_in[95:88]),   .data_out(sub_bytes_out[95:88]));
    aes_sbox sbox_5  (.data_in(state_in[87:80]),   .data_out(sub_bytes_out[87:80]));
    aes_sbox sbox_6  (.data_in(state_in[79:72]),   .data_out(sub_bytes_out[79:72]));
    aes_sbox sbox_7  (.data_in(state_in[71:64]),   .data_out(sub_bytes_out[71:64]));
    aes_sbox sbox_8  (.data_in(state_in[63:56]),   .data_out(sub_bytes_out[63:56]));
    aes_sbox sbox_9  (.data_in(state_in[55:48]),   .data_out(sub_bytes_out[55:48]));
    aes_sbox sbox_10 (.data_in(state_in[47:40]),   .data_out(sub_bytes_out[47:40]));
    aes_sbox sbox_11 (.data_in(state_in[39:32]),   .data_out(sub_bytes_out[39:32]));
    aes_sbox sbox_12 (.data_in(state_in[31:24]),   .data_out(sub_bytes_out[31:24]));
    aes_sbox sbox_13 (.data_in(state_in[23:16]),   .data_out(sub_bytes_out[23:16]));
    aes_sbox sbox_14 (.data_in(state_in[15:8]),    .data_out(sub_bytes_out[15:8]));
    aes_sbox sbox_15 (.data_in(state_in[7:0]),     .data_out(sub_bytes_out[7:0]));

    // ShiftRows
    aes_shift_rows shift_rows_inst (
        .data_in(sub_bytes_out),
        .data_out(shift_rows_out)
    );

    // MixColumns (skipped for final round)
    aes_mix_columns mix_columns_inst (
        .data_in(shift_rows_out),
        .data_out(mix_columns_out)
    );

    // Mux between MixColumns output and ShiftRows output (for final round)
    wire [127:0] before_add_key = is_final ? shift_rows_out : mix_columns_out;

    // AddRoundKey
    aes_add_round_key add_round_key_inst (
        .data_in(before_add_key),
        .round_key(round_key),
        .data_out(add_round_key_out)
    );

    assign state_out = add_round_key_out;

endmodule
