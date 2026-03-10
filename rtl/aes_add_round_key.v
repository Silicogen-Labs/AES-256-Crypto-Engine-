//////////////////////////////////////////////////////////////////////////////
// Module: aes_add_round_key
// Description: AES AddRoundKey transformation
//              XORs the state with the round key
//
// Author: SilicogenAI
// Date: 2026-03-10
//////////////////////////////////////////////////////////////////////////////

module aes_add_round_key (
    input  [127:0] data_in,
    input  [127:0] round_key,
    output [127:0] data_out
);

    // Simple 128-bit XOR
    assign data_out = data_in ^ round_key;

endmodule
