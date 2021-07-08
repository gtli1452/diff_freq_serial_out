/* Filename : uart_rx.v
 * Simulator: ModelSim - Intel FPGA Edition vsim 2020.1
 * Complier : Quartus Prime - Standard Edition 20.1.1
 *
 * This file contains the UART Receiver. It is able to receive 8 bits of
 * serial data, one start bit, one stop bit, and no parity bit. When receive is
 * complete rx_done_tick_o will be driven high for one clock cycle.
 *
 * The source code is modified from:
 * Pong P. Chu - FPGA Prototyping By Verilog Examples
 */

module uart_rx #(
  parameter DATA_BITS = 8,
  parameter STOP_TICK = 16
) (
  input                  clk_i,
  input                  rst_ni,
  input                  sample_tick_i,
  input                  rx_i,
  output reg             rx_done_tick_o,
  output [DATA_BITS-1:0] rx_data_o
);

// Define the states
localparam [1:0]    S_IDLE  = 2'b00;
localparam [1:0]    S_START = 2'b01;
localparam [1:0]    S_DATA  = 2'b10;
localparam [1:0]    S_STOP  = 2'b11;

// Signal declaration
reg [1:0]           state_reg, state_next;
reg [3:0]           tick_count_reg, tick_count_next; // sample_tick_i counter
reg [2:0]           data_count_reg, data_count_next; // data bit counter
reg [DATA_BITS-1:0] data_buf_reg, data_buf_next;     // data buf
reg                 rx_reg, rx_next;

// Body
// FSMD state & data registers
always @(posedge clk_i, negedge rst_ni) begin
  if (~rst_ni)
    begin
      state_reg      <= S_IDLE;
      tick_count_reg <= 0;
      data_count_reg <= 0;
      data_buf_reg   <= 0;
      rx_reg         <= 1'b1;
    end
  else
    begin
      state_reg      <= state_next;
      tick_count_reg <= tick_count_next;
      data_count_reg <= data_count_next;
      data_buf_reg   <= data_buf_next;
      rx_reg         <= rx_next;
    end
end

// FSMD next-state logic
always @(*) begin
  state_next      = state_reg;
  tick_count_next = tick_count_reg;
  data_count_next = data_count_reg;
  data_buf_next   = data_buf_reg;
  rx_done_tick_o  = 1'b0;
  rx_next         = rx_i;

  case (state_reg)
    // S_Idle: waiting for the start bit
    S_IDLE: begin
      if (~rx_reg)
        begin
          state_next      = S_START;
          tick_count_next = 0;
        end
    end // case: S_IDLE

    // S_START: sample the middle of the start bit
    S_START: begin
      if (sample_tick_i)
        begin
          if (tick_count_reg == 4'h7) // sample the middle of start bit (16 ticks per bit)
            begin
              if (~rx_reg) // check rx is low at START bit
                begin
                  state_next      = S_DATA;
                  tick_count_next = 0;
                  data_count_next = 0;
                end
              else
                  state_next      = S_IDLE;
            end
          else
            tick_count_next = tick_count_reg + 1'b1;
        end
    end // case: S_START

    // S_DATA: sample the middle of each data bit
    S_DATA: begin
      if (sample_tick_i)
        begin
          if (tick_count_reg == 4'hF)
            begin
              tick_count_next = 0;
              data_buf_next   = {rx_reg, data_buf_reg[7:1]}; // right-shit 1-bit
              if (data_count_reg == (DATA_BITS - 1'b1))
                state_next = S_STOP;
              else
                data_count_next = data_count_reg + 1'b1;
            end
          else
            tick_count_next = tick_count_reg + 1'b1;
        end
    end // case: S_DATA

    // S_STOP: sample the stop bit, and assert rx_done_tick_o
    S_STOP: begin
      if (sample_tick_i)
        begin
          if (tick_count_reg == (STOP_TICK - 1'b1))
            begin
              state_next     = S_IDLE;
              rx_done_tick_o = 1'b1;
            end
          else
            tick_count_next = tick_count_reg + 1'b1;
        end
    end // case: S_STOP

    default: state_next = S_IDLE;
  endcase
end

// Output
assign rx_data_o = data_buf_reg;

endmodule