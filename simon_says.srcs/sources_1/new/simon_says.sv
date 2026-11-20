`timescale 1ns / 1ps

module simon_says (
    input  logic        clk,              // 100 MHz system clock
    input  logic        speed_up_pulse,   // 1-cycle pulse from btnU
    input  logic        speed_down_pulse, // 1-cycle pulse from btnD
    input  logic        start_game_pulse, // 1-cycle pulse from btnC
    input  logic [15:0] sw_sync,          // Debounced switch states (stay in position)
    input  logic [3:0]  rightmost_sw,     // Latched upper lane bound (0..15)
    output logic [1:0]  game_state,       // 0: IDLE, 1: SHOW_SEQ, 2: PLAYER_TURN, 3: GAME_OVER
    output logic        seq_led_on,       // 1 while illuminating a sequence step
    output logic [3:0]  active_lane,      // Active sequence lane (0..15)
    output logic [3:0]  speed_lvl,        // Speed setting (0..9)
    output logic [13:0] score             // Player score (0..9999)
);

    localparam int MAX_SEQ_LEN = 64;

    // -------------------------------------------------------------------------
    // Datapath Signals, Tick Generator Wires & Status Flags
    // -------------------------------------------------------------------------
    logic [3:0]  latched_speed; // Latched speed_lvl (0..9) for the active game
    // TODO: Declare sequence memory, sequence length, playback/turn step indices,
    // and previous-cycle switch state (sw_prev) as needed.

    logic        reset_tick_cnt;
    logic        led_on_phase;
    logic        step_tick;

    logic        seq_done;
    logic        wrong_input;
    logic        turn_done;

    // -------------------------------------------------------------------------
    // Controller FSMD Instantiation
    // -------------------------------------------------------------------------
    fsmd u_fsmd (
        .clk              (clk),
        .start_game_pulse (start_game_pulse),
        .seq_done         (seq_done),
        .wrong_input      (wrong_input),
        .turn_done        (turn_done),
        .game_state       (game_state)
    );

    // -------------------------------------------------------------------------
    // Speed-Driven Tick Generator Instantiation
    // -------------------------------------------------------------------------
    tick_gen u_tick_gen (
        .clk          (clk),
        .active       (game_state == 2'd1),
        .reset_cnt    (reset_tick_cnt),
        .speed_active (latched_speed),
        .led_on_phase (led_on_phase),
        .step_tick    (step_tick)
    );

    // -------------------------------------------------------------------------
    // Combinational Status Flags & Glue Logic
    // -------------------------------------------------------------------------
    always_comb begin
        // TODO: Drive reset_tick_cnt (e.g., on game start or round transition)
        // TODO: Drive seq_done when final sequence step finishes playback
        // TODO: Drive wrong_input when a switch toggles to the wrong lane in S_PLAYER_TURN
        // TODO: Drive turn_done when a matching switch toggle completes the round
        reset_tick_cnt = 1'b0;
        seq_done       = 1'b0;
        wrong_input    = 1'b0;
        turn_done      = 1'b0;
    end

    // -------------------------------------------------------------------------
    // Sequential Datapath Logic (Playback, Switch Check & Turn Progression)
    // -------------------------------------------------------------------------
    always_ff @(posedge clk) begin
        // TODO: Update sw_prev <= sw_sync every clock edge

        case (game_state)
            2'd0: begin // S_IDLE
                // TODO: Adjust speed_lvl on speed_up_pulse / speed_down_pulse
                if (start_game_pulse) begin
                    latched_speed <= speed_lvl;
                    // TODO: Initialize sequence memory, sequence length, step indices, and score
                end
            end

            2'd1: begin // S_SHOW_SEQ
                // TODO: Drive active_lane from sequence memory and gate seq_led_on with led_on_phase
                // TODO: Advance display step index on step_tick up to seq_len - 1
                // TODO: Handle mid-game start_game_pulse restart if desired
            end

            2'd2: begin // S_PLAYER_TURN
                // TODO: Keep seq_led_on = 0
                // TODO: Detect switch toggles (sw_sync ^ sw_prev), compare against expected sequence lane
                // TODO: Advance turn step index on match, or increment score and seq_len on final step
                // TODO: Handle mid-game start_game_pulse restart if desired
            end

            2'd3: begin // S_GAME_OVER
                // TODO: Keep seq_led_on = 0 and handle start_game_pulse return/reconfiguration
            end

            default: begin
                // TODO: Safe fallback assignments
            end
        endcase
    end

    // -------------------------------------------------------------------------
    // Power-Up Defaults
    // -------------------------------------------------------------------------
    initial begin
        speed_lvl     = 4'd5;
        latched_speed = 4'd5;
        score         = 14'd0;
        active_lane   = 4'd0;
        seq_led_on    = 1'b0;
        // TODO: Initialize sequence memory, sequence length, step indices, and sw_prev
    end

endmodule