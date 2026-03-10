//////////////////////////////////////////////////////////////////////////////
// Module: aes_mix_columns
// Description: AES MixColumns transformation
//              Mixes each column of the state using GF(2^8) multiplication
//
// For each column [a, b, c, d]:
//   a' = (02*a) XOR (03*b) XOR c XOR d
//   b' = a XOR (02*b) XOR (03*c) XOR d
//   c' = a XOR b XOR (02*c) XOR (03*d)
//   d' = (03*a) XOR b XOR c XOR (02*d)
//
// Author: SilicogenAI
// Date: 2026-03-10
//////////////////////////////////////////////////////////////////////////////

module aes_mix_columns (
    input  [127:0] data_in,
    output [127:0] data_out
);

    // GF(2^8) multiplication by 2 (xtime)
    // xtime(x) = (x << 1) XOR (x[7] ? 0x1B : 0x00)
    function [7:0] xtime;
        input [7:0] b;
        begin
            xtime = (b << 1) ^ (b[7] ? 8'h1b : 8'h00);
        end
    endfunction

    // GF(2^8) multiplication by 3
    // 03*x = xtime(x) XOR x
    function [7:0] mul3;
        input [7:0] b;
        begin
            mul3 = xtime(b) ^ b;
        end
    endfunction

    // Mix a single column
    function [31:0] mix_column;
        input [31:0] col_in;  // {a, b, c, d}
        reg [7:0] a, b, c, d;
        reg [7:0] a2, b2, c2, d2;  // x2 values
        reg [7:0] a3, b3, c3, d3;  // x3 values
        begin
            a = col_in[31:24];
            b = col_in[23:16];
            c = col_in[15:8];
            d = col_in[7:0];

            a2 = xtime(a);
            b2 = xtime(b);
            c2 = xtime(c);
            d2 = xtime(d);

            a3 = a2 ^ a;  // mul3(a)
            b3 = b2 ^ b;  // mul3(b)
            c3 = c2 ^ c;  // mul3(c)
            d3 = d2 ^ d;  // mul3(d)

            // a' = 02*a + 03*b + c + d
            mix_column[31:24] = a2 ^ b3 ^ c ^ d;
            // b' = a + 02*b + 03*c + d
            mix_column[23:16] = a ^ b2 ^ c3 ^ d;
            // c' = a + b + 02*c + 03*d
            mix_column[15:8]  = a ^ b ^ c2 ^ d3;
            // d' = 03*a + b + c + 02*d
            mix_column[7:0]   = a3 ^ b ^ c ^ d2;
        end
    endfunction

    // Extract columns from input
    wire [31:0] col0 = data_in[127:96];
    wire [31:0] col1 = data_in[95:64];
    wire [31:0] col2 = data_in[63:32];
    wire [31:0] col3 = data_in[31:0];

    // Mix each column
    assign data_out = {mix_column(col0), mix_column(col1), mix_column(col2), mix_column(col3)};

endmodule
