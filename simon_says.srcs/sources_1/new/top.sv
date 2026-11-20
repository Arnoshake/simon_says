`timescale 1ns / 1ps

module top (
    input  logic        clk,   // 100 MHz system clock (pin W5)
    input  logic        btnU,  // Up pushbutton: speed increase in pregame (pin T18)
    input  logic        btnC,  // Center pushbutton: start / restart game (pin U18)
    input  logic        btnD,  // Down pushbutton: speed decrease in pregame (pin U17)
    input  logic [15:0] sw,    // 16 slide switches
    output logic [15:0] led,   // 16 discrete LEDs
    output logic [6:0]  seg,   // Shared active-low 7-segment cathodes (CA..CG)
    output logic        dp,    // Shared active-low decimal point
    output logic [3:0]  an     // Active-low digit enable anodes (AN0..AN3)
);

    // -------------------------------------------------------------------------
    // 1. BUTTONS
    // -------------------------------------------------------------------------

    // -------------------------------------------------------------------------
    // 1a. Button 2-Flip-Flop Synchronizers (Async -> 100 MHz clk domain)
    // -------------------------------------------------------------------------
    (* ASYNC_REG = "TRUE" *) logic [1:0] sync_u, sync_c, sync_d; // 2-FF shift registers per button
    logic       btnU_sync, btnC_sync, btnD_sync;

    assign btnU_sync = sync_u[1]; // Synchronized output for btnU
    assign btnC_sync = sync_c[1]; // Synchronized output for btnC
    assign btnD_sync = sync_d[1]; // Synchronized output for btnD

    always_ff @(posedge clk) begin
        sync_u <= {sync_u[0], btnU};
        sync_c <= {sync_c[0], btnC};
        sync_d <= {sync_d[0], btnD};
    end

    // -------------------------------------------------------------------------
    // 1b. Button Debouncers (~10 ms stability filter @ 100 MHz)
    // -------------------------------------------------------------------------
    localparam int DEBOUNCE_MAX = 999_999; // 1,000,000 cycles = 10 ms @ 100 MHz

    logic [19:0] cnt_u, cnt_c, cnt_d;     // Steady-state counters per button
    logic        clean_u, clean_c, clean_d; // Debounced (bounce-free) button states

    always_ff @(posedge clk) begin
        // Debounce synchronized btnU
        if (btnU_sync == clean_u) begin
            cnt_u <= 20'd0; // State matches; reset timer
        end else if (cnt_u == DEBOUNCE_MAX) begin
            clean_u <= btnU_sync; // Held steady for 10 ms; accept new state
            cnt_u   <= 20'd0;
        end else begin
            cnt_u <= cnt_u + 20'd1; // Count cycles while different
        end

        // Debounce synchronized btnC
        if (btnC_sync == clean_c) begin
            cnt_c <= 20'd0;
        end else if (cnt_c == DEBOUNCE_MAX) begin
            clean_c <= btnC_sync;
            cnt_c   <= 20'd0;
        end else begin
            cnt_c <= cnt_c + 20'd1;
        end

        // Debounce synchronized btnD
        if (btnD_sync == clean_d) begin
            cnt_d <= 20'd0;
        end else if (cnt_d == DEBOUNCE_MAX) begin
            clean_d <= btnD_sync;
            cnt_d   <= 20'd0;
        end else begin
            cnt_d <= cnt_d + 20'd1;
        end
    end

    // -------------------------------------------------------------------------
    // 1c. Button Rising-Edge Pulse Generators (1 clock cycle per press)
    // -------------------------------------------------------------------------
    logic prev_u, prev_c, prev_d; // Previous-cycle debounced button states

    wire speed_up_pulse   = clean_u & ~prev_u; // 1-cycle pulse when btnU goes 0 -> 1
    wire start_game_pulse = clean_c & ~prev_c; // 1-cycle pulse when btnC goes 0 -> 1
    wire speed_down_pulse = clean_d & ~prev_d; // 1-cycle pulse when btnD goes 0 -> 1

    always_ff @(posedge clk) begin
        prev_u <= clean_u;
        prev_c <= clean_c;
        prev_d <= clean_d;
    end

    // -------------------------------------------------------------------------
    // 2. SWITCHES
    // -------------------------------------------------------------------------

    // -------------------------------------------------------------------------
    // 2a. Switch 2-Flip-Flop Synchronizers (Async -> 100 MHz clk domain)
    // -------------------------------------------------------------------------
    (* ASYNC_REG = "TRUE" *) logic [15:0] sw_s1, sw_s2;

    always_ff @(posedge clk) begin
        sw_s1 <= sw;
        sw_s2 <= sw_s1;
    end

    // -------------------------------------------------------------------------
    // 2b. Switch Debouncers (~10 ms stability filter @ 100 MHz) & Toggle Detect
    // -------------------------------------------------------------------------
    logic [19:0] sw_cnt [0:15];
    logic [15:0] sw_clean;
    logic [15:0] sw_prev;

    always_ff @(posedge clk) begin
        sw_prev <= sw_clean;

        for (int i = 0; i < 16; i++) begin
            if (sw_s2[i] == sw_clean[i]) begin
                sw_cnt[i] <= 20'd0;
            end else if (sw_cnt[i] == DEBOUNCE_MAX[19:0]) begin
                sw_clean[i] <= sw_s2[i];
                sw_cnt[i]   <= 20'd0;
            end else begin
                sw_cnt[i] <= sw_cnt[i] + 20'd1;
            end
        end
    end

    // -------------------------------------------------------------------------
    // 2c. Establishing the "Event Lane" (Rightmost ON switch latched at start)
    // -------------------------------------------------------------------------
    // Rightmost ON switch (lowest index 0..15; sw[0] is rightmost) latched at
    // game start sets the inclusive upper switch index (0..15) for sequence lanes.
    logic [3:0] rightmost_sw_comb;
    logic [3:0] rightmost_sw;

    always_comb begin
        rightmost_sw_comb = 4'd0;

        if      (sw_clean[0])  rightmost_sw_comb = 4'd0;
        else if (sw_clean[1])  rightmost_sw_comb = 4'd1;
        else if (sw_clean[2])  rightmost_sw_comb = 4'd2;
        else if (sw_clean[3])  rightmost_sw_comb = 4'd3;
        else if (sw_clean[4])  rightmost_sw_comb = 4'd4;
        else if (sw_clean[5])  rightmost_sw_comb = 4'd5;
        else if (sw_clean[6])  rightmost_sw_comb = 4'd6;
        else if (sw_clean[7])  rightmost_sw_comb = 4'd7;
        else if (sw_clean[8])  rightmost_sw_comb = 4'd8;
        else if (sw_clean[9])  rightmost_sw_comb = 4'd9;
        else if (sw_clean[10]) rightmost_sw_comb = 4'd10;
        else if (sw_clean[11]) rightmost_sw_comb = 4'd11;
        else if (sw_clean[12]) rightmost_sw_comb = 4'd12;
        else if (sw_clean[13]) rightmost_sw_comb = 4'd13;
        else if (sw_clean[14]) rightmost_sw_comb = 4'd14;
        else if (sw_clean[15]) rightmost_sw_comb = 4'd15;
    end

    // Latch rightmost active switch on start_game_pulse (default 4'd3 if none ON)
    always_ff @(posedge clk) begin
        if (start_game_pulse) begin
            rightmost_sw <= (|sw_clean) ? rightmost_sw_comb : 4'd3;
        end
    end

    // -------------------------------------------------------------------------
    // 3. Core Game Engine (Hardware-Agnostic)
    // -------------------------------------------------------------------------
    logic [1:0]  game_state;    // 0: IDLE, 1: SHOW_SEQ, 2: PLAYER_TURN, 3: GAME_OVER
    logic        seq_led_on;    // 1 while a sequence step is illuminated
    logic [3:0]  active_lane;   // Current sequence lane (0..15)
    logic [3:0]  speed_lvl;     // Selected speed (0..9)
    logic [13:0] score;         // Current player score (0..9999)

    simon_says u_game (
        .clk              (clk),
        .speed_up_pulse   (speed_up_pulse),
        .speed_down_pulse (speed_down_pulse),
        .start_game_pulse (start_game_pulse),
        .sw_sync          (sw_clean),
        .rightmost_sw     (rightmost_sw),
        .game_state       (game_state),
        .seq_led_on       (seq_led_on),
        .active_lane      (active_lane),
        .speed_lvl        (speed_lvl),
        .score            (score)
    );

    // -------------------------------------------------------------------------
    // 4. LED Peripheral Driver (led[15:0])
    // -------------------------------------------------------------------------
    localparam int PULSE_CYCLES = 14_999_999; // ~150 ms visible pulse @ 100 MHz

    logic [3:0]  clamped_speed;
    logic [15:0] speed_bar;
    logic [23:0] pulse_cnt [0:15];
    logic [15:0] led_pulse;
    wire  [15:0] sw_toggled = sw_clean ^ sw_prev;

    always_ff @(posedge clk) begin
        for (int i = 0; i < 16; i++) begin
            if (game_state != 2'd2) begin
                pulse_cnt[i] <= 24'd0;
            end else if (sw_toggled[i]) begin
                pulse_cnt[i] <= PULSE_CYCLES[23:0];
            end else if (pulse_cnt[i] != 24'd0) begin
                pulse_cnt[i] <= pulse_cnt[i] - 24'd1;
            end
        end
    end

    always_comb begin
        for (int i = 0; i < 16; i++) begin
            led_pulse[i] = (pulse_cnt[i] != 24'd0);
        end

        clamped_speed = (speed_lvl <= 4'd9) ? speed_lvl : 4'd9;
        speed_bar     = (16'h0001 << clamped_speed) - 16'h0001;
        led           = 16'h0000;

        case (game_state)
            2'd0: begin // IDLE: solid speed bar (0..9) + blink unused LEDs
                led = speed_bar | (~speed_bar & {16{anim_cnt[24]}});
            end
            2'd1: begin // SHOW_SEQ: light active sequence lane (0..15)
                if (seq_led_on)
                    led[active_lane] = 1'b1;
            end
            2'd2: begin // PLAYER_TURN: pulse LEDs when corresponding switch toggles
                led = led_pulse;
            end
            2'd3: begin // GAME_OVER: flash all LEDs
                led = anim_cnt[24] ? 16'hFFFF : 16'h0000;
            end
            default: led = 16'h0000;
        endcase
    end

    // -------------------------------------------------------------------------
    // 5. Animation Counter for Blinking LEDs
    // -------------------------------------------------------------------------
    logic [27:0] anim_cnt = 28'd0;

    always_ff @(posedge clk) begin
        anim_cnt <= anim_cnt + 28'd1;
    end

    // -------------------------------------------------------------------------
    // 6. 7-Segment Display Multiplexer & Decoder
    // -------------------------------------------------------------------------
    // Basys3 7-segment display has 4 digits left-to-right:
    //   [1] = digit3 (AN3), [2] = digit2 (AN2), [3] = digit1 (AN1), [4] = digit0 (AN0)
    //
    // Cathodes (seg[6:0] = {g, f, e, d, c, b, a}) and anodes (an[3:0]) are active-low:
    //   0 = ON, 1 = OFF.
    localparam logic [6:0] OFF   = 7'b1111111;
    localparam logic [6:0] SEG_A = 7'b1111110; // Top bar
    localparam logic [6:0] SEG_B = 7'b1111101; // Top-right bar
    localparam logic [6:0] SEG_C = 7'b1111011; // Bottom-right bar
    localparam logic [6:0] SEG_D = 7'b1110111; // Bottom bar
    localparam logic [6:0] SEG_E = 7'b1101111; // Bottom-left bar
    localparam logic [6:0] SEG_F = 7'b1011111; // Top-left bar
    localparam logic [6:0] SEG_G = 7'b0111111; // Middle bar

    typedef enum logic [4:0] {
        G_0, G_1, G_2, G_3, G_4,
        G_5, G_6, G_7, G_8, G_9,
        G_S, G_P, G_D, G_L, G_O, G_E,
        G_BLANK
    } seg_glyph_t;

    seg_glyph_t  digit3 = G_BLANK; // [1] Leftmost (AN3)
    seg_glyph_t  digit2 = G_BLANK; // [2]          (AN2)
    seg_glyph_t  digit1 = G_BLANK; // [3]          (AN1)
    seg_glyph_t  digit0 = G_BLANK; // [4] Rightmost(AN0)
    seg_glyph_t  active_glyph = G_BLANK;

    logic [16:0] refresh_cnt = 17'd0;
    logic [1:0]  mux_sel = 2'd0;

    // 1. Choose what each of the 4 digits should display
    always_comb begin
        digit3 = G_BLANK;
        digit2 = G_BLANK;
        digit1 = G_BLANK;
        digit0 = G_BLANK;

        case (game_state)
            2'd0: begin
                // Pregame: [S][P][D][speed_lvl]
                digit3 = G_S;
                digit2 = G_P;
                digit1 = G_D;
                digit0 = (speed_lvl <= 4'd9) ? seg_glyph_t'(speed_lvl) : G_9;
            end
            2'd1, 2'd2: begin
                // Active game: decimal score across [1][2][3][4]
                digit3 = seg_glyph_t'((score / 14'd1000) % 14'd10);
                digit2 = seg_glyph_t'((score / 14'd100)  % 14'd10);
                digit1 = seg_glyph_t'((score / 14'd10)   % 14'd10);
                digit0 = seg_glyph_t'( score              % 14'd10);
            end
            2'd3: begin
                // Game over: [L][O][S][E]
                digit3 = G_L;
                digit2 = G_O;
                digit1 = G_S;
                digit0 = G_E;
            end
            default: begin
                digit3 = G_BLANK;
                digit2 = G_BLANK;
                digit1 = G_BLANK;
                digit0 = G_BLANK;
            end
        endcase
    end

    // 2. Time-multiplexing counter (~763 Hz across 4 digits at 100 MHz)
    always_ff @(posedge clk) begin
        refresh_cnt <= refresh_cnt + 17'd1;
        mux_sel     <= refresh_cnt[16:15];
    end

    // 3. Select active digit anode (active-low: 0 = enabled)
    always_comb begin
        an           = 4'b1111;
        active_glyph = G_BLANK;
        dp           = 1'b1; // Decimal point off (active-low)

        case (mux_sel)
            2'd0: begin an = 4'b1110; active_glyph = digit0; end // [4] AN0
            2'd1: begin an = 4'b1101; active_glyph = digit1; end // [3] AN1
            2'd2: begin an = 4'b1011; active_glyph = digit2; end // [2] AN2
            2'd3: begin an = 4'b0111; active_glyph = digit3; end // [1] AN3
        endcase
    end

    // 4. Decode glyph into active-low segment cathodes {g, f, e, d, c, b, a}
    always_comb begin
        case (active_glyph)
            G_0:     seg = SEG_A & SEG_B & SEG_C & SEG_D & SEG_E & SEG_F;
            G_1:     seg = SEG_B & SEG_C;
            G_2:     seg = SEG_A & SEG_B & SEG_D & SEG_E & SEG_G;
            G_3:     seg = SEG_A & SEG_B & SEG_C & SEG_D & SEG_G;
            G_4:     seg = SEG_B & SEG_C & SEG_F & SEG_G;
            G_5:     seg = SEG_A & SEG_C & SEG_D & SEG_F & SEG_G;
            G_6:     seg = SEG_A & SEG_C & SEG_D & SEG_E & SEG_F & SEG_G;
            G_7:     seg = SEG_A & SEG_B & SEG_C;
            G_8:     seg = SEG_A & SEG_B & SEG_C & SEG_D & SEG_E & SEG_F & SEG_G;
            G_9:     seg = SEG_A & SEG_B & SEG_C & SEG_D & SEG_F & SEG_G;
            G_S:     seg = SEG_A & SEG_C & SEG_D & SEG_F & SEG_G;
            G_P:     seg = SEG_A & SEG_B & SEG_E & SEG_F & SEG_G;
            G_D:     seg = SEG_B & SEG_C & SEG_D & SEG_E & SEG_G; // lowercase 'd'
            G_L:     seg = SEG_D & SEG_E & SEG_F;
            G_O:     seg = SEG_A & SEG_B & SEG_C & SEG_D & SEG_E & SEG_F;
            G_E:     seg = SEG_A & SEG_D & SEG_E & SEG_F & SEG_G;
            G_BLANK: seg = OFF;
            default: seg = OFF;
        endcase
    end

endmodule