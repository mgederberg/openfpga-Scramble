module scramble_adapter (
    input  wire        clk_sys,
    input  wire        reset,
    input  wire [31:0] keys,
    input  wire        cheat_lives,

    input  wire [15:0] rom_addr,
    input  wire [7:0]  rom_data,
    input  wire        rom_wr,

    output wire [23:0] rgb,
    output wire        hs,
    output wire        vs,
    output wire        hblank,
    output wire        vblank,
    output wire [9:0]  audio
);

    // Original MiSTer Scramble clock-enable generation.
    // clk_sys = 24.576 MHz.
    reg [1:0] div = 0;
    // Fractional 1.78975 MHz enable from 24.576 MHz.
    reg [24:0] sound_phase = 25'd0;

    reg ce_12 = 0;
    reg ce_6p = 0;
    reg ce_6n = 0;
    reg ce_1p79 = 0;

    always @(posedge clk_sys) begin
        div <= div + 2'd1;

        ce_12 <= div[0];
        ce_6p <= div[0] & ~div[1];
        ce_6n <= div[0] & div[1];

        // Fractional accumulator; one-cycle enable pulse on carry.
        // 24,576,000 input cycles / second.
        // 1,789,750 desired sound enables / second.
        if (sound_phase >= 25'd22786250) begin
            sound_phase <= sound_phase - 25'd22786250;
            ce_1p79 <= 1'b1;
        end else begin
            sound_phase <= sound_phase + 25'd1789750;
            ce_1p79 <= 1'b0;
        end
    end

    // Pocket button mapping.
    wire m_up      = keys[0];
    wire m_down    = keys[1];
    wire m_left    = keys[2];
    wire m_right   = keys[3];

    wire m_fire_a  = keys[4];
    wire m_fire_b  = keys[5];

    wire m_coin    = keys[14];
    wire m_start1  = keys[15];

    // Reproduce original Scramble input polarity.
    wire [7:0] input0 =
        ~{m_coin, 1'b0, m_left, m_right,
          m_fire_a, 1'b0, m_fire_b, m_up};

    wire [7:0] input1 =
        (~{m_start1, 1'b0, m_left, m_right,
          m_fire_a, m_fire_b, 2'b00} & 8'hFC) | (cheat_lives ? 8'h03 : 8'h00);

    wire [7:0] input2 =
        (~{1'b0, m_down, 1'b0, m_up,
           3'b000, m_down}) & 8'hF9;
    // Coinage DIP bits [2:1] = 00: 1 coin / 1 credit.

    wire [7:0] input3 = 8'hFF;

    wire [7:0] r, g, b;

    assign rgb = {r, g, b};

    SCRAMBLE_TOP arcade (
        .O_VIDEO_R        (r),
        .O_VIDEO_G        (g),
        .O_VIDEO_B        (b),
        .O_HSYNC          (hs),
        .O_VSYNC          (vs),
        .O_HBLANK         (hblank),
        .O_VBLANK         (vblank),
        .O_AUDIO          (audio),

        .I_PA             (input0),
        .I_PB             (input1),
        .I_PC             (input2),
        .I_PD             (input3),

        .I_HWSEL          (0),
        .I_GALAXIAN_VIDEO (1'b0),

        .RESET            (reset),
        .clk              (clk_sys),
        .ena_12           (ce_12),
        .ena_6            (ce_6p),
        .ena_6b           (ce_6n),
        .ena_1_79         (ce_1p79),

        .dl_addr          (rom_addr),
        .dl_wr            (rom_wr),
        .dl_data          (rom_data),

        .pause            (1'b0),
        .hs_address       (11'd0),
        .hs_data_out      (),
        .hs_data_in       (8'd0),
        .hs_write         (1'b0),
        .FlipVertical     (1'b0)
    );

endmodule
