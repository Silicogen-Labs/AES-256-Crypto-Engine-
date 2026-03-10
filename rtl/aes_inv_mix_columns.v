//////////////////////////////////////////////////////////////////////////////
// Module: aes_inv_mix_columns
// Description: AES Inverse MixColumns transformation
//              Uses multipliers 0x0e, 0x0b, 0x0d, 0x09 in GF(2^8)
//
// For each column [a, b, c, d]:
//   a' = (0e*a) XOR (0b*b) XOR (0d*c) XOR (09*d)
//   b' = (09*a) XOR (0e*b) XOR (0b*c) XOR (0d*d)
//   c' = (0d*a) XOR (09*b) XOR (0e*c) XOR (0b*d)
//   d' = (0b*a) XOR (0d*b) XOR (09*c) XOR (0e*d)
//
// Author: SilicogenAI
// Date: 2026-03-10
//////////////////////////////////////////////////////////////////////////////

module aes_inv_mix_columns (
    input  [127:0] data_in,
    output [127:0] data_out
);

    // GF(2^8) multiplication by 2 (xtime)
    function [7:0] xtime;
        input [7:0] b;
        begin
            xtime = (b << 1) ^ (b[7] ? 8'h1b : 8'h00);
        end
    endfunction

    // GF(2^8) multiplication by 4 (xtime(xtime(x)))
    function [7:0] mul4;
        input [7:0] b;
        begin
            mul4 = xtime(xtime(b));
        end
    endfunction

    // GF(2^8) multiplication by 8 (xtime(xtime(xtime(x))))
    function [7:0] mul8;
        input [7:0] b;
        begin
            mul8 = xtime(xtime(xtime(b)));
        end
    endfunction

    // GF(2^8) multiplication by 9 (8+1)
    function [7:0] mul9;
        input [7:0] b;
        begin
            mul9 = mul8(b) ^ b;
        end
    endfunction

    // GF(2^8) multiplication by 11 (8+2+1)
    function [7:0] mul11;
        input [7:0] b;
        begin
            mul11 = mul8(b) ^ xtime(b) ^ b;
        end
    endfunction

    // GF(2^8) multiplication by 13 (8+4+1)
    function [7:0] mul13;
        input [7:0] b;
        begin
            mul13 = mul8(b) ^ mul4(b) ^ b;
        end
    endfunction

    // GF(2^8) multiplication by 14 (8+4+2)
    function [7:0] mul14;
        input [7:0] b;
        begin
            mul14 = mul8(b) ^ mul4(b) ^ xtime(b);
        end
    endfunction

    // Inverse mix a single column
    function [31:0] inv_mix_column;
        input [31:0] col_in;  // {a, b, c, d}
        reg [7:0] a, b, c, d;
        begin
            a = col_in[31:24];
            b = col_in[23:16];
            c = col_in[15:8];
            d = col_in[7:0];

            // a' = 0e*a + 0b*b + 0d*c + 09*d
            inv_mix_column[31:24] = mul14(a) ^ mul11(b) ^ mul13(c) ^ mul9(d);
            // b' = 09*a + 0e*b + 0b*c + 0d*d
            inv_mix_column[23:16] = mul9(a) ^ mul14(b) ^ mul11(c) ^ mul13(d);
            // c' = 0d*a + 09*b + 0e*c + 0b*d
            inv_mix_column[15:8]  = mul13(a) ^ mul9(b) ^ mul14(c) ^ mul11(d);
            // d' = 0b*a + 0d*b + 09*c + 0e*d
            inv_mix_column[7:0]   = mul11(a) ^ mul13(b) ^ mul9(c) ^ mul14(d);
        end
    endfunction

    // Extract columns from input
    wire [31:0] col0 = data_in[127:96];
    wire [31:0] col1 = data_in[95:64];
    wire [31:0] col2 = data_in[63:32];
    wire [31:0] col3 = data_in[31:0];

    // Inverse mix each column
    assign data_out = {inv_mix_column(col0), inv_mix_column(col1), inv_mix_column(col2), inv_mix_column(col3)};

endmodule
