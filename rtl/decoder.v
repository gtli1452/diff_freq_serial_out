/* Filename : decoder.v
 * Simulator: ModelSim - Intel FPGA Edition vsim 2020.1
 * Complier : Quartus Prime - Standard Edition 20.1.1
 *
 * Decoder the uart received data
 */

`include "user_cmd.vh"

module decoder #(
  parameter DATA_BIT   = 32,
  parameter DATA_NUM   = 5,
  parameter FREQ_NUM   = 4,
  parameter PERIOD_NUM = 2
) (
  input                     clk_i,
  input                     rst_ni,
  input      [7:0]          data_i,
  input                     rx_done_tick_i,
  output reg [7:0]          amount_o,
  output reg [DATA_BIT-1:0] output_pattern_o,
  output reg [DATA_BIT-1:0] freq_pattern_o,
  output reg [7:0]          sel_out_o,
  output reg                enable_o,
  output reg                run_o,
  output reg                idle_o,
  output reg [1:0]          mode_o,
  output reg [7:0]          slow_period_o,
  output reg [7:0]          fast_period_o,
  output reg [7:0]          repeat_o,
  output reg [7:0]          cmd_o,
  output reg                done_tick_o
);

  /* State declaration */
  localparam [3:0] S_IDLE   = 4'b0000;
  localparam [3:0] S_FREQ   = 4'b0001;
  localparam [3:0] S_DATA   = 4'b0010;
  localparam [3:0] S_PERIOD = 4'b0011;
  localparam [3:0] S_GLOBAL = 4'b0101;
  localparam [3:0] S_CTRL   = 4'b0110;
  localparam [3:0] S_REPEAT = 4'b0111;
  localparam [3:0] S_DONE   = 4'b1000;
  localparam [3:0] S_AMOUNT = 4'b1001;
  localparam [3:0] S_SELECT = 4'b1010;

  /* Parameter declaration */
  localparam PACK_BIT   = 8 * DATA_NUM; // 32-bit data_pattern, 8-bit control
  localparam FREQ_BIT   = 8 * FREQ_NUM; // 32-bit freq_pattern, 8-bit low_period, 8-bit high_period

  /* Signal declaration */
  reg [3:0]          state_reg, state_next;
  reg [7:0]          amount_reg, amount_next;
  reg [7:0]          select_reg, select_next;
  reg [PACK_BIT-1:0] data_buf_reg, data_buf_next;
  reg [FREQ_BIT-1:0] freq_buf_reg, freq_buf_next;
  reg [15:0]         ctrl_reg, ctrl_next;
  reg [15:0]         period_reg, period_next; // slow_period + fast_period
  reg [15:0]         repeat_reg, repeat_next;
  reg [7:0]          global_reg, global_next;
  reg [7:0]          count_reg, count_next;
  reg [7:0]          cmd_reg, cmd_next;

  /* Body */
  /* FSMD state & data registers */
  always @(posedge clk_i, negedge rst_ni) begin
    if (~rst_ni)
      begin
        state_reg    <= S_IDLE;
        amount_reg   <= 0;
        select_reg   <= 0;
        data_buf_reg <= 0;
        freq_buf_reg <= 0;
        ctrl_reg     <= 0;
        period_reg   <= 0;
        repeat_reg   <= 0;
        global_reg   <= 0;
        count_reg    <= 0;
        cmd_reg      <= 0;
      end
    else
      begin
        state_reg    <= state_next;
        amount_reg   <= amount_next;
        select_reg   <= select_next;
        data_buf_reg <= data_buf_next;
        freq_buf_reg <= freq_buf_next;
        ctrl_reg     <= ctrl_next;
        period_reg   <= period_next;
        repeat_reg   <= repeat_next;
        global_reg   <= global_next;
        count_reg    <= count_next;
        cmd_reg      <= cmd_next;
      end
  end

  /* FSMD next-state logic & functional units */
  always @(*) begin
    state_next       = state_reg; // default state : the same
    amount_next      = amount_reg;
    select_next      = select_reg;
    data_buf_next    = data_buf_reg;
    freq_buf_next    = freq_buf_reg;
    ctrl_next        = ctrl_reg;
    period_next      = period_reg;
    repeat_next      = repeat_reg;
    global_next      = global_reg;
    count_next       = count_reg;
    cmd_next         = cmd_reg;
    done_tick_o      = 0;
    amount_o         = 0;
    output_pattern_o = 0;
    freq_pattern_o   = 0;
    enable_o         = 0;
    run_o            = 0;
    idle_o           = 0;
    mode_o           = 0;
    sel_out_o        = 0;
    slow_period_o    = 0;
    fast_period_o    = 0;
    repeat_o         = 0;
    cmd_o            = 0;

    case (state_reg)
      S_IDLE: begin
        count_next = 0;
        if (rx_done_tick_i)
          begin
            cmd_next = data_i;
            if (cmd_next == `CMD_DATA)
              state_next = S_SELECT;
            else if (cmd_next == `CMD_FREQ)
              state_next = S_FREQ;
            else if (cmd_next == `CMD_PERIOD)
              state_next = S_PERIOD;
            else if (cmd_next == `CMD_CTRL)
              state_next = S_SELECT;
            else if (cmd_next == `CMD_REPEAT)
              state_next = S_SELECT;
            else if (cmd_next == `CMD_GLOBAL)
              state_next = S_GLOBAL;
            else
              state_next = S_IDLE;
          end
      end

      S_FREQ: begin
        if (rx_done_tick_i)
          begin
            freq_buf_next = {data_i, freq_buf_reg[FREQ_BIT-1:8]}; // right shift 8-bit
            count_next = count_reg + 1'b1;
          end
        else if (count_reg == FREQ_NUM)
          begin
            count_next = 0;
            state_next = S_DONE;
          end
      end

      S_PERIOD: begin
        if (rx_done_tick_i)
          begin
            period_next = {data_i, period_reg[15:8]}; // right-shift 8-bit
            count_next = count_reg + 1'b1;
          end
        else if (count_reg == PERIOD_NUM)
          begin
            count_next = 0;
            state_next = S_DONE;
          end
      end

      S_SELECT: begin
        if (rx_done_tick_i)
          begin
            select_next = data_i;
            if (cmd_next == `CMD_DATA)
              state_next = S_DATA;
            else if (cmd_next == `CMD_CTRL)
              state_next = S_CTRL;
            else if (cmd_next == `CMD_REPEAT)
              state_next = S_REPEAT;
            else
              state_next = S_IDLE;
          end
      end

      S_CTRL: begin
        if (rx_done_tick_i)
          begin
            ctrl_next = data_i;
            state_next = S_DONE;
          end
      end

      S_REPEAT: begin
        if (rx_done_tick_i)
          begin
            repeat_next = data_i;
            state_next = S_DONE;
          end
      end

      S_GLOBAL: begin
        if (rx_done_tick_i)
          begin
            global_next = data_i;
            state_next = S_DONE;
          end
      end

      S_AMOUNT: begin
        if (rx_done_tick_i)
          begin
            amount_next = data_i;
            state_next = S_DATA;
          end
      end

      S_DATA: begin
        if (rx_done_tick_i)
          begin
            data_buf_next = {data_i, data_buf_reg[PACK_BIT-1:8]}; // right-shift 8-bit
            count_next = count_reg + 1'b1;
          end
        else if (count_reg == DATA_NUM)
          begin
            count_next = 0;
            state_next = S_DONE;
          end
      end

      S_DONE: begin
        done_tick_o = 1'b1;
        cmd_o = cmd_reg;
        state_next = S_IDLE;
        if (cmd_reg == `CMD_DATA)
          begin
            sel_out_o = select_reg[7:0];
            output_pattern_o = data_buf_reg[DATA_BIT-1:0];
          end
        else if (cmd_reg == `CMD_FREQ)
          begin
            freq_pattern_o = freq_buf_reg[DATA_BIT-1:0];
          end
        else if (cmd_reg == `CMD_PERIOD)
          begin
            fast_period_o = period_reg[15:8];
            slow_period_o = period_reg[7:0];
          end
        else if (cmd_reg == `CMD_CTRL)
          begin
            sel_out_o = select_reg;
            enable_o = ctrl_reg[0];
            mode_o = ctrl_reg[2:1];
            idle_o = ctrl_reg[3];
          end
        else if (cmd_reg == `CMD_REPEAT)
          begin
            sel_out_o = select_reg;
            repeat_o = repeat_reg[7:0];
          end
        else if (cmd_reg == `CMD_GLOBAL)
          begin
            run_o = global_reg[0];
          end
      end

      default: state_next = S_IDLE;
    endcase
  end

  /* Output logic */

endmodule