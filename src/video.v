`default_nettype none
module video (
  input         clk,
  input         reset,
  output [3:0]  vga_r,
  output [3:0]  vga_b,
  output [3:0]  vga_g,
  output        vga_hs,
  output        vga_vs,
  output        vga_de,
  input  [7:0]  vga_data,
  output [12:0] vga_addr,
  input  [7:0]  attr_data,
  output [12:0] attr_addr,
  output        n_int
);

  parameter HA = 640;
  parameter HS  = 96;
  parameter HFP = 16;
  parameter HBP = 48;
  parameter HT  = HA + HS + HFP + HBP;
  parameter HB = 64;

  parameter VA = 480;
  parameter VS  = 2;
  parameter VFP = 11;
  parameter VBP = 31;
  parameter VT  = VA + VS + VFP + VBP;
  parameter VB = 48;

  reg [9:0] hc = 0;
  reg [9:0] vc = 0;
  reg INT = 0;
  reg[5:0] intCnt = 1;

  assign n_int = !INT;

  always @(posedge clk) begin
    if (hc == HT - 1) begin
      hc <= 0;
      if (vc == VT - 1) vc <= 0;
      else vc <= vc + 1;
    end else hc <= hc + 1;
    if (hc == HA + HFP && vc == VA + VFP) INT <= 1;
    if (INT) intCnt <= intCnt + 1;
    if (!intCnt) INT <= 0;
  end

  assign vga_hs = !(hc >= HA + HFP && hc < HA + HFP + HS);
  assign vga_vs = !(vc >= VA + VFP && vc < VA + VFP + VS);
  assign vga_de = !(hc > HA || vc > VA);

  wire [7:0] x = (hc - HB) >> 1;
  wire [7:0] y = (vc - VB) >> 1;

  assign vga_addr = {y[7:6], y[2:0], y[5:3], x[7:3]};
  assign attr_addr = 13'h1800 + {3'b0, y[7:3], x[7:3]};

  wire hBorder = (hc < HB || hc >= HA - HB);
  wire vBorder = (vc < VB || vc >= VA - VB);
  wire border = hBorder || vBorder;

  wire [2:0] ink = attr_data[2:0];
  wire [2:0] paper = attr_data[5:3];
  wire bright = attr_data[6];
  wire flash = attr_data[7];

  wire ink_red = ink[1];
  wire ink_green = ink[2];
  wire ink_blue = ink[0];

  wire paper_red = paper[1];
  wire paper_green = paper[2];
  wire paper_blue = paper[0];

  wire pixel = vga_data[~x[2:0]];

  reg [2:0] border_color = 3'b111;

  wire red = border ? border_color[1] : pixel ? ink_red : paper_red;
  wire green = border ? border_color[2] : pixel ? ink_green : paper_green;
  wire blue = border ? border_color[0] : pixel ? ink_blue : paper_blue;

  assign vga_r = !vga_de ? 4'b0 : {bright, {3{red}}};
  assign vga_g = !vga_de ? 4'b0 : {bright, {3{green}}};
  assign vga_b = !vga_de ? 4'b0 : {bright, {3{blue}}};

endmodule
