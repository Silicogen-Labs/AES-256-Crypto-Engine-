//////////////////////////////////////////////////////////////////////////////
// Module: aes_inv_round
// Description: Single AES decryption round
//              Combines InvShiftRows, InvSubBytes, AddRoundKey, and InvMixColumns
//
// Note: Order is different from encryption:
//       InvShiftRows -> InvSubBytes -> AddRoundKey -> InvMixColumns
//
// Author: SilicogenAI
// Date: 2026-03-10
//////////////////////////////////////////////////////////////////////////////

module aes_inv_round (
    input  [127:0] state_in,
    input  [127:0] round_key,
    input          is_final,      // 1 = final round (no InvMixColumns)
    output [127:0] state_out
);

    // Internal signals
    wire [127:0] inv_shift_rows_out;
    wire [127:0] inv_sub_bytes_out;
    wire [127:0] add_round_key_out;
    wire [127:0] inv_mix_columns_out;

    // InvShiftRows (first in decryption)
    aes_inv_shift_rows inv_shift_rows_inst (
        .data_in(state_in),
        .data_out(inv_shift_rows_out)
    );

    // InvSubBytes - 16 parallel inverse S-Box lookups
    aes_inv_sbox inv_sbox_0  (.data_in(inv_shift_rows_out[127:120]), .data_out(inv_sub_bytes_out[127:120]));
    aes_inv_sbox inv_sbox_1  (.data_in(inv_shift_rows_out[119:112]), .data_out(inv_sub_bytes_out[119:112]));
    aes_inv_sbox inv_sbox_2  (.data_in(inv_shift_rows_out[111:104]), .data_out(inv_sub_bytes_out[111:104]));
    aes_inv_sbox inv_sbox_3  (.data_in(inv_shift_rows_out[103:96]),  .data_out(inv_sub_bytes_out[103:96]));
    aes_inv_sbox inv_sbox_4  (.data_in(inv_shift_rows_out[95:88]),   .data_out(inv_sub_bytes_out[95:88]));
    aes_inv_sbox inv_sbox_5  (.data_in(inv_shift_rows_out[87:80]),   .data_out(inv_sub_bytes_out[87:80]));
    aes_inv_sbox inv_sbox_6  (.data_in(inv_shift_rows_out[79:72]),   .data_out(inv_sub_bytes_out[79:72]));
    aes_inv_sbox inv_sbox_7  (.data_in(inv_shift_rows_out[71:64]),   .data_out(inv_sub_bytes_out[71:64]));
    aes_inv_sbox inv_sbox_8  (.data_in(inv_shift_rows_out[63:56]),   .data_out(inv_sub_bytes_out[63:56]));
    aes_inv_sbox inv_sbox_9  (.data_in(inv_shift_rows_out[55:48]),   .data_out(inv_sub_bytes_out[55:48]));
    aes_inv_sbox inv_sbox_10 (.data_in(inv_shift_rows_out[47:40]),   .data_out(inv_sub_bytes_out[47:40]));
    aes_inv_sbox inv_sbox_11 (.data_in(inv_shift_rows_out[39:32]),   .data_out(inv_sub_bytes_out[39:32]));
    aes_inv_sbox inv_sbox_12 (.data_in(inv_shift_rows_out[31:24]),   .data_out(inv_sub_bytes_out[31:24]));
    aes_inv_sbox inv_sbox_13 (.data_in(inv_shift_rows_out[23:16]),   .data_out(inv_sub_bytes_out[23:16]));
    aes_inv_sbox inv_sbox_14 (.data_in(inv_shift_rows_out[15:8]),    .data_out(inv_sub_bytes_out[15:8]));
    aes_inv_sbox inv_sbox_15 (.data_in(inv_shift_rows_out[7:0]),     .data_out(inv_sub_bytes_out[7:0]));

    // AddRoundKey
    aes_add_round_key add_round_key_inst (
        .data_in(inv_sub_bytes_out),
        .round_key(round_key),
        .data_out(add_round_key_out)
    );

    // InvMixColumns (skipped for final round)
    aes_inv_mix_columns inv_mix_columns_inst (
        .data_in(add_round_key_out),
        .data_out(inv_mix_columns_out)
    );

    // Mux between InvMixColumns output and AddRoundKey output (for final round)
    assign state_out = is_final ? add_round_key_out : inv_mix_columns_out;

endmodule
