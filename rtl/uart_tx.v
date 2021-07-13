  /* Filename : uart_tx.v
  * Simulator: ModelSim - Intel FPGA Edition vsim 2020.1
  * Complier : Quartus Prime - Standard Edition 20.1.1
  *
  * This file contains the UART Transmitter. It is able to transmit 8 bits of
  * serial data, one start bit, one stop bit, and no parity bit. When transmit is
  * complete tx_done_tick_o will be driven high for one clock cycle.
  *
  * The source code is modified from:
  * Pong P. Chu - FPGA Prototyping By Verilog Examples
  */

module uart_tx #(
  parameter DATA_BITS = 8,
  parameter STOP_TICK = 16
) (
  input                 clk_i,
  input                 rst_ni,
  input                 sample_tick_i,
  input                 tx_start_i,
  input [DATA_BITS-1:0] tx_data_i,
  output                tx_o,
  output reg            tx_done_tick_o
);

  /* State declaration */
  localparam [1:0] S_IDLE  = 2'b00;
  localparam [1:0] S_START = 2'b01;
  localparam [1:0] S_DATA  = 2'b10;
  localparam [1:0] S_STOP  = 2'b11;

  /* Signal declaration */
  reg [2:0]           state_reg, state_next;
  reg [3:0]           tick_count_reg, tick_count_next; // sample_tick_i counter
  reg [2:0]           data_count_reg, data_count_next; // data bit counter
  reg [DATA_BITS-1:0] data_buf_reg, data_buf_next;     // data buf
  reg                 tx_reg, tx_next;

  /* Body */
  /* FSMD state & data registers */
  always @(posedge clk_i or negedge rst_ni) begin
    if (~rst_ni)
      begin
        state_reg      <= S_IDLE;
        tick_count_reg <= 0;
        data_count_reg <= 0;
        data_buf_reg   <= 0;
        tx_reg         <= 1'b1;
      end
    else
      begin
        state_reg      <= state_next;
        tick_count_reg <= tick_count_next;
        data_count_reg <= data_count_next;
        data_buf_reg   <= data_buf_next;
        tx_reg         <= tx_next;
      end
  end

  /* FSMD next-state logic & functional units */
  always @(*) begin
    state_next      = state_reg;
    tick_count_next = tick_count_reg;
    data_count_next = data_count_reg;
    data_buf_next   = data_buf_reg;
    tx_next         = tx_reg;
    tx_done_tick_o  = 1'b0;

    case (state_reg)
      // S_IDLE: waiting for the tx_start_i
      S_IDLE: begin
        tx_next = 1'b1; // idle state is high level
        if (tx_start_i)
          begin
            state_next = S_START;
            tick_count_next = 0;
            data_buf_next = tx_data_i;
          end
      end // case: S_IDLE

      // S_START: transmit the start bit
      S_START: begin
        tx_next = 1'b0;
        if (sample_tick_i)
          begin
            if (tick_count_reg == 4'hF)
              begin
                state_next = S_DATA;
                tick_count_next = 0;
                data_count_next = 0;
              end
            else
              tick_count_next = tick_count_reg + 1'b1;
          end
      end // case: S_START

      // S_DATA: transmit the 8 data bits
      S_DATA: begin
        tx_next = data_buf_reg[0]; // transmit LSB first
        if (sample_tick_i)
        begin
          if (tick_count_reg == 4'hF)
            begin
              tick_count_next = 0;
              data_buf_next = data_buf_reg >> 1;
              if (data_count_reg == (DATA_BITS - 1))
                state_next = S_STOP;
              else
                data_count_next = data_count_reg + 1'b1;
            end
          else
            tick_count_next = tick_count_reg + 1'b1;
        end
      end // case: S_DATA

      // S_STOP: transmit the stop bit, and assert tx_done_tick_o
      S_STOP: begin
        tx_next = 1'b1;
        if (sample_tick_i)
          begin
            if (tick_count_reg == ((STOP_TICK - 1'b1) >> 1))
              begin
                state_next = S_IDLE;
                tx_done_tick_o = 1'b1;
              end
            else
              tick_count_next = tick_count_reg + 1'b1;
          end
      end // case S_STOP

      default: state_next = S_IDLE;
    endcase
  end

    /* Output */
    assign tx_o = tx_reg;

endmodule