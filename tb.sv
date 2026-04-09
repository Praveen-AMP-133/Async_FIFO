`timescale 1ns/1ps
module tb_async_fifo;

    parameter DEPTH = 8;
    parameter WIDTH = 8;
    localparam ADDR_WIDTH = $clog2(DEPTH);

    reg                   clk_a;
    reg                   clk_b;
    reg                   rst_a;
    reg                   rst_b;

    reg  [ADDR_WIDTH-1:0] addr_a;
    reg  [ADDR_WIDTH-1:0] addr_b;

    reg                   wr_en;
    reg                   rd_en;

    reg  [WIDTH-1:0]      data_in;
    wire [WIDTH-1:0]      data_out;

    wire full;
    wire empty;

    // DUT
    async_fifo #(
        .WIDTH(WIDTH),
        .DEPTH(DEPTH)
    ) dut (
        .clk_a   (clk_a),
        .rst_a   (rst_a),
        .addr_a  (addr_a),
        .data_in (data_in),
        .wr_en   (wr_en),

        .clk_b   (clk_b),
        .rst_b   (rst_b),
        .addr_b  (addr_b),
        .rd_en   (rd_en),

        .full    (full),
        .empty   (empty),
        .data_out(data_out)
    );

    // -------------------------
    // Clock generation
    // -------------------------
    always #5 clk_a = ~clk_a;   // write clock
    always #3 clk_b = ~clk_b;   // read clock

    // -------------------------
    // WRITE SIDE (clk_a domain)
    // -------------------------
    always @(negedge clk_a) begin
        if (wr_en && !full) begin
            data_in <= data_in + 1;
            addr_a  <= addr_a + 1;
        end
    end

    // -------------------------
    // READ SIDE (clk_b domain)
    // -------------------------
    always @(negedge clk_b) begin
        if (rd_en && !empty) begin
            addr_b <= addr_b + 1;
        end
    end

    // -------------------------
    // Stimulus control
    // -------------------------
    initial begin
        clk_a  = 0;
        clk_b  = 0;
        rst_a  = 0;
        rst_b  = 0;

        wr_en  = 0;
        rd_en  = 0;

        addr_a = 0;
        addr_b = 0;
        data_in = 8'hA0;

        // Reset
        #10;
        rst_a = 1;
        rst_b = 1;

        // Start write
        @(negedge clk_a);
        wr_en = 1;

        // Start read after some delay
        #40;
        @(negedge clk_b);
        rd_en = 1;

        // Run simulation
        #300 $finish;
    end

    // -------------------------
    // Monitor
    // -------------------------
    initial begin
        $monitor("T=%0t | wr_en=%0b rd_en=%0b | full=%0b empty=%0b | data_out=%0h",
                  $time, wr_en, rd_en, full, empty, data_out);
    end

    // -------------------------
    // Dump
    // -------------------------
    initial begin
        $dumpfile("async_fifo.vcd");
        $dumpvars(0, tb_async_fifo);
    end

endmodule
