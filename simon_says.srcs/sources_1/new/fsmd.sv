`timescale 1ns / 1ps

module fsmd (
    input  logic        clk,
    input  logic        start_game_pulse,
    input  logic        seq_done,
    input  logic        wrong_input,
    input  logic        turn_done,
    input  logic        return_to_idle,
    output logic [1:0]  game_state
);

    // -------------------------------------------------------------------------
    // State Encoding
    // -------------------------------------------------------------------------
    typedef enum logic [1:0] {
        S_IDLE        = 2'd0,
        S_SHOW_SEQ    = 2'd1,
        S_PLAYER_TURN = 2'd2,
        S_GAME_OVER   = 2'd3
    } state_t;

    state_t state      = S_IDLE;
    state_t next_state;

    assign game_state = state;

    // -------------------------------------------------------------------------
    // Next-State Combinational Logic
    // -------------------------------------------------------------------------
    always_comb begin
        next_state = state;

        case (state)
            S_IDLE: begin
                if (start_game_pulse) begin
                    next_state = S_SHOW_SEQ;
                end
            end

            S_SHOW_SEQ: begin
                if (seq_done) begin
                    next_state = S_PLAYER_TURN;
                end
            end

            S_PLAYER_TURN: begin
                if (wrong_input) begin
                    next_state = S_GAME_OVER;
                end else if (turn_done) begin
                    next_state = S_SHOW_SEQ;
                end
            end

            S_GAME_OVER: begin
                if (start_game_pulse) begin
                    next_state = S_SHOW_SEQ; // Quick restart
                end else if (return_to_idle) begin //QUESTION: should we have this separate flag or should we bring in all the inputs?
                    next_state = S_IDLE; // Change the game configuration
                end
            end

            default: begin
                next_state = S_IDLE;
            end
        endcase
    end
    

    // -------------------------------------------------------------------------
    // State Register Update
    // -------------------------------------------------------------------------
    always_ff @(posedge clk) begin
        state <= next_state;
    end

endmodule