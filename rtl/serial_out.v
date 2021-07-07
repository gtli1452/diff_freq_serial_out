/* Filename : serial_out.v
 * Simulator: ModelSim - Intel FPGA Edition vsim 2020.1
 * Complier : Quartus Prime - Standard Edition 20.1.1
 *
 * Serially output 32-bit data by different frequency
 */

module serial_out #(
  parameter DATA_BIT = 32
) (
  input                 clk_i,
  input                 rst_ni,
  input                 enable_i,
  input                 stop_i,
  input  [1:0]          mode_i,        // b00:one-shot, b01:repeat, b10:repeat n_times
  input  [DATA_BIT-1:0] output_pattern_i,
  input  [DATA_BIT-1:0] freq_pattern_i,
  input  [7:0]          slow_period_i,
  input  [7:0]          fast_period_i,
  input  [7:0]          repeat_i,
  output                serial_out_o,  // idle state is low
  output                done_tick_o
);

  // Define the states
  localparam [1:0] S_IDLE     = 2'b00;
  localparam [1:0] S_UPDATE   = 2'b01;
  localparam [1:0] S_ONE_SHOT = 2'b10;
  localparam [1:0] S_DONE     = 2'b11;

  localparam IDLE     = 1'b0;
  localparam ONE_SHOT = 2'b00;
  localparam CONTINUE = 2'b01;
  localparam REPEAT   = 2'b10;

  // Signal declaration
  reg [1:0]          state_reg,     state_next;
  reg [1:0]          mode_reg,      mode_next;
  reg                output_reg,    output_next;
  reg [5:0]          data_bit_reg,  data_bit_next;
  reg [DATA_BIT-1:0] data_buf_reg,  data_buf_next;
  reg [DATA_BIT-1:0] freq_buf_reg,  freq_buf_next;
  reg [7:0]          slow_period,   slow_period_next;
  reg [7:0]          fast_period,   fast_period_next;
  reg [7:0]          repeat_reg,    repeat_next;
  reg [7:0]          count_reg,     count_next;
  reg                done_tick_reg, done_tick_next;

  // Body
  // FSMD state & data registers
  always @(posedge clk_i, negedge rst_ni) begin
    if (~rst_ni)
      begin
        state_reg     <= S_IDLE;
        mode_reg      <= 0;
        output_reg    <= 0;
        data_bit_reg  <= 0;
        data_buf_reg  <= 0;
        freq_buf_reg  <= 0;
        slow_period   <= 0;
        fast_period   <= 0;
        repeat_reg    <= 0;
        count_reg     <= 0;
        done_tick_reg <= 0;
      end
    else
      begin
        state_reg     <= state_next;
        mode_reg      <= mode_next;
        output_reg    <= output_next;
        data_bit_reg  <= data_bit_next;
        data_buf_reg  <= data_buf_next;
        freq_buf_reg  <= freq_buf_next;
        slow_period   <= slow_period_next;
        fast_period   <= fast_period_next;
        repeat_reg    <= repeat_next;
        count_reg     <= count_next;
        done_tick_reg <= done_tick_next;
      end
  end

  // FSMD next-state logic
  always @(*) begin
    state_next       = state_reg;
    mode_next        = mode_reg;
    output_next      = output_reg;
    data_bit_next    = data_bit_reg;
    data_buf_next    = data_buf_reg;
    freq_buf_next    = freq_buf_reg;
    slow_period_next = slow_period;
    fast_period_next = fast_period;
    repeat_next      = repeat_reg;
    count_next       = count_reg;
    done_tick_next   = 0;

    case (state_reg)
      S_IDLE: begin
        output_next = IDLE;
        if (enable_i)
          state_next = S_UPDATE; // load the input data
      end

      S_UPDATE: begin
        state_next       = S_ONE_SHOT;
        mode_next        = mode_i;
        data_buf_next    = output_pattern_i;
        freq_buf_next    = freq_pattern_i;
        slow_period_next = slow_period_i;
        fast_period_next = fast_period_i;
        data_bit_next    = 0;
        if (freq_buf_next[0])
          count_next = fast_period_next - 1'b1;
        else
          count_next = slow_period_next - 1'b1;
      end

      // change per bit period depending on freq_pattern
      S_ONE_SHOT: begin
        output_next = data_buf_reg[data_bit_reg]; // transmit lsb first
        if (stop_i)
          state_next = S_IDLE;
        else if (enable_i)
          state_next = S_UPDATE;
        else if (count_reg == 0)
          begin
            if (data_bit_reg == (DATA_BIT - 1))
              state_next = S_DONE;
            else
              data_bit_next = data_bit_reg + 1'b1;

            if (freq_buf_reg[data_bit_next]) // to get the next-bit period, use "data_bit_next"
              count_next = fast_period_next - 1'b1;
            else
              count_next = slow_period_next - 1'b1;
          end
        else
          count_next = count_reg - 1'b1;
      end

      S_DONE: begin
        output_next = IDLE;
        done_tick_next = 1;

        if (mode_reg == CONTINUE)
          state_next = S_UPDATE;
        else if (mode_reg == REPEAT)
          if (repeat_reg >= (repeat_i - 1))
            begin
              state_next = S_IDLE;
              repeat_next = 0;
            end
          else begin
            state_next = S_UPDATE;
            repeat_next = repeat_reg + 1'b1;
          end
        else
          state_next = S_IDLE;
      end

      default: state_next = S_IDLE;
    endcase
  end

  // Output
  assign serial_out_o = output_reg;
  assign done_tick_o  = done_tick_reg;

endmodule
