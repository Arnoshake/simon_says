module tick_gen (
    input  logic       clk,
    input  logic       active,       // High during S_SHOW_SEQ
    input  logic       reset_cnt,    // Clears counter on round/game start
    input  logic [3:0] speed_active, // Latched speed (0..9)
    output logic       led_on_phase, // High during first half of step
    output logic       step_tick     // 1-cycle pulse at end of step interval
);
    // TODO: Compute interval target from speed_active (0 = slowest, 9 = fastest)
    // TODO: Count cycles while active; reset when !active or reset_cnt
    // TODO: Drive led_on_phase and 1-cycle step_tick
endmodule