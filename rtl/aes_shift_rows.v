//////////////////////////////////////////////////////////////////////////////
// Module: aes_shift_rows
// Description: AES ShiftRows transformation
//              Cyclically shifts rows of the state matrix
//
// Row 0: no shift
// Row 1: shift left by 1 byte
// Row 2: shift left by 2 bytes
// Row 3: shift left by 3 bytes
//
// Author: SilicogenAI
// Date: 2026-03-10
//////////////////////////////////////////////////////////////////////////////

module aes_shift_rows (
    input  [127:0] data_in,
    output [127:0] data_out
);

    // Extract bytes from input (column-major order)
    // data_in = {col3, col2, col1, col0}
    // col0 = {s0, s1, s2, s3}
    // col1 = {s4, s5, s6, s7}
    // col2 = {s8, s9, s10, s11}
    // col3 = {s12, s13, s14, s15}

    wire [7:0] s0  = data_in[127:120];  // Row 0, Col 0
    wire [7:0] s1  = data_in[119:112];  // Row 1, Col 0
    wire [7:0] s2  = data_in[111:104];  // Row 2, Col 0
    wire [7:0] s3  = data_in[103:96];   // Row 3, Col 0
    wire [7:0] s4  = data_in[95:88];    // Row 0, Col 1
    wire [7:0] s5  = data_in[87:80];    // Row 1, Col 1
    wire [7:0] s6  = data_in[79:72];    // Row 2, Col 1
    wire [7:0] s7  = data_in[71:64];    // Row 3, Col 1
    wire [7:0] s8  = data_in[63:56];    // Row 0, Col 2
    wire [7:0] s9  = data_in[55:48];    // Row 1, Col 2
    wire [7:0] s10 = data_in[47:40];    // Row 2, Col 2
    wire [7:0] s11 = data_in[39:32];    // Row 3, Col 2
    wire [7:0] s12 = data_in[31:24];    // Row 0, Col 3
    wire [7:0] s13 = data_in[23:16];    // Row 1, Col 3
    wire [7:0] s14 = data_in[15:8];     // Row 2, Col 3
    wire [7:0] s15 = data_in[7:0];      // Row 3, Col 3

    // After ShiftRows:
    // Row 0: s0, s4, s8, s12  (no shift)
    // Row 1: s5, s9, s13, s1  (shift left by 1)
    // Row 2: s10, s14, s2, s6 (shift left by 2)
    // Row 3: s15, s3, s7, s11 (shift left by 3)

    // Output in column-major order (MSB first)
    // col0' = {s0, s5, s10, s15}
    // col1' = {s4, s9, s14, s3}
    // col2' = {s8, s13, s2, s7}
    // col3' = {s12, s1, s6, s11}

    assign data_out = {s0, s5, s10, s15,   // col0' at bits [127:96]
                       s4, s9, s14, s3,    // col1' at bits [95:64]
                       s8, s13, s2, s7,    // col2' at bits [63:32]
                       s12, s1, s6, s11};  // col3' at bits [31:0]

endmodule
