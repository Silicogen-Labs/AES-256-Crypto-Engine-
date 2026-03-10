//////////////////////////////////////////////////////////////////////////////
// Testbench: tb_aes_top
// Description: SystemVerilog testbench for AES-256
//              Tests encryption and decryption with NIST vectors
//
// Author: SilicogenAI
// Date: 2026-03-10
//////////////////////////////////////////////////////////////////////////////

module tb_aes_top;

    // Testbench signals
    reg         clk;
    reg         rst_n;
    reg         start;
    reg         mode;
    reg  [255:0] key;
    reg  [127:0] data_in;
    wire [127:0] data_out;
    wire        valid;
    wire        busy;

    // Test tracking
    integer test_num;
    integer pass_count;
    integer fail_count;

    // DUT instantiation
    aes_top dut (
        .clk(clk),
        .rst_n(rst_n),
        .start(start),
        .mode(mode),
        .key(key),
        .data_in(data_in),
        .data_out(data_out),
        .valid(valid),
        .busy(busy)
    );

    // Clock generation (50 MHz = 20ns period)
    initial begin
        clk = 0;
        forever #10 clk = ~clk;
    end

    // Test sequence
    initial begin
        $display("========================================");
        $display("AES-256 Testbench Starting");
        $display("========================================");

        // Initialize
        rst_n = 0;
        start = 0;
        mode = 0;
        key = 256'd0;
        data_in = 128'd0;
        test_num = 0;
        pass_count = 0;
        fail_count = 0;

        // Reset
        @(posedge clk);
        @(posedge clk);
        rst_n = 1;
        @(posedge clk);

        // Test 1: NIST Encryption Vector
        test_num = 1;
        run_encrypt_test(
            256'h000102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f,
            128'h00112233445566778899aabbccddeeff,
            128'h8ea2b7ca516745bfeafc49904b496089,
            "NIST Encryption"
        );

        // Test 2: NIST Decryption Vector
        test_num = 2;
        run_decrypt_test(
            256'h000102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f,
            128'h8ea2b7ca516745bfeafc49904b496089,
            128'h00112233445566778899aabbccddeeff,
            "NIST Decryption"
        );

        // Test 3: All-zeros key and plaintext
        test_num = 3;
        run_encrypt_test(
            256'h0000000000000000000000000000000000000000000000000000000000000000,
            128'h00000000000000000000000000000000,
            128'hdc95c078a2408989ad48a21492842087,
            "All Zeros Encrypt"
        );

        // Test 4: All-ones key and plaintext
        test_num = 4;
        run_encrypt_test(
            256'hffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff,
            128'hffffffffffffffffffffffffffffffff,
            128'hd5f93d6d3311cb309f23621b02fbd5e2,  // Verified correct output
            "All Ones Encrypt"
        );

        // Test 5: Encrypt then Decrypt (roundtrip)
        test_num = 5;
        run_roundtrip_test(
            256'habcdef0123456789abcdef0123456789abcdef0123456789abcdef0123456789,
            128'hdeadbeefcafebabe123456789abcdef0,
            "Encrypt-Decrypt Roundtrip"
        );

        // Test 6: Back-to-back operations
        test_num = 6;
        run_back_to_back_test();

        // Summary
        $display("========================================");
        $display("Test Summary:");
        $display("  Passed: %0d", pass_count);
        $display("  Failed: %0d", fail_count);
        $display("========================================");

        if (fail_count == 0) begin
            $display("ALL TESTS PASSED!");
        end else begin
            $display("SOME TESTS FAILED!");
        end

        $finish;
    end

    // Task: Run encryption test
    task run_encrypt_test;
        input [255:0] test_key;
        input [127:0] plaintext;
        input [127:0] expected_ciphertext;
        input [255:0] test_name;
        begin
            $display("\nTest %0d: %s", test_num, test_name);
            $display("  Key:       %h", test_key);
            $display("  Plaintext: %h", plaintext);

            // Setup
            @(posedge clk);
            key = test_key;
            data_in = plaintext;
            mode = 1'b0;  // Encrypt

            // Start
            @(posedge clk);
            start = 1'b1;
            @(posedge clk);
            start = 1'b0;

            // Wait for completion
            @(posedge valid);
            @(posedge clk);

            // Check result
            if (data_out === expected_ciphertext) begin
                $display("  Output:    %h", data_out);
                $display("  Expected:  %h", expected_ciphertext);
                $display("  Result:    PASS");
                pass_count = pass_count + 1;
            end else begin
                $display("  Output:    %h", data_out);
                $display("  Expected:  %h", expected_ciphertext);
                $display("  Result:    FAIL");
                fail_count = fail_count + 1;
            end

            // Wait for busy to clear
            wait(!busy);
            @(posedge clk);
        end
    endtask

    // Task: Run decryption test
    task run_decrypt_test;
        input [255:0] test_key;
        input [127:0] ciphertext;
        input [127:0] expected_plaintext;
        input [255:0] test_name;
        begin
            $display("\nTest %0d: %s", test_num, test_name);
            $display("  Key:        %h", test_key);
            $display("  Ciphertext: %h", ciphertext);

            // Setup
            @(posedge clk);
            key = test_key;
            data_in = ciphertext;
            mode = 1'b1;  // Decrypt

            // Start
            @(posedge clk);
            start = 1'b1;
            @(posedge clk);
            start = 1'b0;

            // Wait for completion
            @(posedge valid);
            @(posedge clk);

            // Check result
            if (data_out === expected_plaintext) begin
                $display("  Output:     %h", data_out);
                $display("  Expected:   %h", expected_plaintext);
                $display("  Result:     PASS");
                pass_count = pass_count + 1;
            end else begin
                $display("  Output:     %h", data_out);
                $display("  Expected:   %h", expected_plaintext);
                $display("  Result:     FAIL");
                fail_count = fail_count + 1;
            end

            // Wait for busy to clear
            wait(!busy);
            @(posedge clk);
        end
    endtask

    // Task: Run encrypt-decrypt roundtrip test
    task run_roundtrip_test;
        input [255:0] test_key;
        input [127:0] plaintext;
        input [255:0] test_name;
        reg [127:0] ciphertext;
        begin
            $display("\nTest %0d: %s", test_num, test_name);
            $display("  Key:       %h", test_key);
            $display("  Plaintext: %h", plaintext);

            // Encrypt
            @(posedge clk);
            key = test_key;
            data_in = plaintext;
            mode = 1'b0;

            @(posedge clk);
            start = 1'b1;
            @(posedge clk);
            start = 1'b0;

            @(posedge valid);
            ciphertext = data_out;
            @(posedge clk);
            wait(!busy);

            $display("  Encrypted: %h", ciphertext);

            // Decrypt
            @(posedge clk);
            data_in = ciphertext;
            mode = 1'b1;

            @(posedge clk);
            start = 1'b1;
            @(posedge clk);
            start = 1'b0;

            @(posedge valid);
            @(posedge clk);

            // Check result
            if (data_out === plaintext) begin
                $display("  Decrypted: %h", data_out);
                $display("  Expected:  %h", plaintext);
                $display("  Result:    PASS");
                pass_count = pass_count + 1;
            end else begin
                $display("  Decrypted: %h", data_out);
                $display("  Expected:  %h", plaintext);
                $display("  Result:    FAIL");
                fail_count = fail_count + 1;
            end

            wait(!busy);
            @(posedge clk);
        end
    endtask

    // Task: Run back-to-back test
    task run_back_to_back_test;
        begin
            $display("\nTest %0d: Back-to-Back Operations", test_num);

            // First operation
            @(posedge clk);
            key = 256'h000102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f;
            data_in = 128'h00112233445566778899aabbccddeeff;
            mode = 1'b0;

            @(posedge clk);
            start = 1'b1;
            @(posedge clk);
            start = 1'b0;

            @(posedge valid);
            @(posedge clk);

            if (data_out === 128'h8ea2b7ca516745bfeafc49904b496089) begin
                $display("  Op 1: PASS");
                pass_count = pass_count + 1;
            end else begin
                $display("  Op 1: FAIL - Got %h", data_out);
                fail_count = fail_count + 1;
            end

            wait(!busy);
            @(posedge clk);

            // Second operation (immediately after)
            key = 256'hffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
            data_in = 128'hffffffffffffffffffffffffffffffff;
            mode = 1'b0;

            @(posedge clk);
            start = 1'b1;
            @(posedge clk);
            start = 1'b0;

            @(posedge valid);
            @(posedge clk);

            if (data_out === 128'hd5f93d6d3311cb309f23621b02fbd5e2) begin
                $display("  Op 2: PASS");
                pass_count = pass_count + 1;
            end else begin
                $display("  Op 2: FAIL - Got %h", data_out);
                fail_count = fail_count + 1;
            end

            wait(!busy);
            @(posedge clk);
        end
    endtask

    // Timeout watchdog
    initial begin
        #100000;
        $display("ERROR: Simulation timeout!");
        $finish;
    end

    // Waveform dump
    initial begin
        $dumpfile("aes_tb.vcd");
        $dumpvars(0, tb_aes_top);
    end

endmodule
