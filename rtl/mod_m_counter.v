module mod_m_counter #(
  parameter MOD     = 65,         // mod-M
  parameter MOD_BIT = $clog2(MOD) // number of bits in counter
) (
  input                clk,
  input                rst_n,
  output               max_tick,
  output [MOD_BIT-1:0] q
);

// Signal declaration
reg  [MOD_BIT-1:0] count_reg;
wire [MOD_BIT-1:0] count_next;

// Body
// Register
always @(posedge clk, negedge rst_n) begin
  if (~rst_n)
    count_reg <= 0;
  else
    count_reg <= count_next;
end

// Next-state logic
assign count_next = (count_reg == (MOD-1)) ? {(MOD_BIT){1'b0}} : count_reg + 1'b1;
// Output logic
assign max_tick   = (count_reg == (MOD-1)) ? 1'b1 : 1'b0;
assign q = count_reg;

endmodule