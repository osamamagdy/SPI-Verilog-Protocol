module Integration(

    input     reg  clk,
    input     reg  reset,
    input     reg  start,              
    input reg[1:0] cs,

    input     reg  load, 
    input reg[7:0] master_data_in,
    input reg[7:0] slave_data_in,
    
    output[7:0] master_data_out,
    output[7:0] slave_data_out,
    
    input reg en_read,

    input reg cpol,
    input reg cpha

);

 wire busy;
 wire cs_out;
 wire data_out_received;
 wire mosi;
 reg reg_mosi;
 wire slave_clk;
 reg  en_write ;
 wire miso;
 reg reg_miso;
 //master  medo(clk,reset,start,master_data_in,load,master_data_out,busy,data_out_received,data_out_received,reg_miso,mosi,slave_clk,cs_out);
 Slave UUT (.cs(0) , .cpol(cpol) , .cpha(cpha) , .clk(slave_clk) , .mosi(reg_mosi) , .miso(miso) , .en_read(en_read) , .read(slave_data_out) , .en_write(load) , .write(slave_data_in) );
 
 always@(posedge clk or  negedge clk)
 begin
  reg_mosi=mosi;
  reg_miso=miso;
 end
endmodule




module integration_tb();

reg  clk;
reg  reset;
reg  start;
reg  [7:0] data_in;
reg  load;
reg  miso_m;
wire [7:0] data_out;
wire busy;
reg  cs_in;
wire cs_out;
wire data_out_received;
wire mosi;
wire slave_clk;



reg flag , cs , cpol , cpha , mosi_s , en_read , en_write ;
reg [7 : 0] write;
wire miso;
wire [7 : 0] read ;

localparam period = 10 ;
integer i;
master  medo(clk,reset,start,master_data_in,load,data_out,busy,data_out_received,cpol,cpha,miso,mosi,slave_clk);
Slave UUT (.cs(cs) , .cpol(cpol) , .cpha(cpha) , .clk(slave_clk) , .mosi(mosi) , .miso(miso) , .en_read(en_read) , .read(read) , .en_write(en_write) , .write(write) );
always
begin
#(period/2) clk = ~clk;
end

initial begin 

$monitor( "slave in binary = %b master in binary = %b " ,read[7:0] , data_out[7:0] );

cpol=0;
cpha=0;
clk = 0;

reset=1;
start = 0;

load = 0;
en_read =0;
en_write = 0;
cs=0;
#(period);
reset=0;
en_write = 1;
write=8'b11111111;
#(period);
en_write = 0;
start=1;
#(period);
start=0;
#(9*period);
en_read =1;
#(period);
$finish;
end
endmodule

module integration_tb2();

reg  clk;
reg  reset;
reg  start;
reg  [7:0] data_in;
reg  load;
wire miso;
wire [7:0] data_out;
wire busy;
reg  cs_in;
wire cs_out;
wire data_out_received;
wire mosi;
wire slave_clk;

reg [1:0] choice;
//Slave1
reg flag , cs , cpol , cpha , mosi_s , en_read , en_write ;
reg [7 : 0] write;
wire miso1;
wire [7 : 0] read ;

//Slave2
reg cs2 , en_read2 , en_write2 ;
reg [7 : 0] write2;
wire miso2;
wire [7 : 0] read2;

//Slave3
reg cs3 , en_read3 , en_write3 ;
reg [7 : 0] write3;
wire miso3;
wire [7 : 0] read3;

localparam period = 10 ;
integer i;
master  medo(clk,reset,start,master_data_in,load,data_out,busy,data_out_received,cpol,cpha,miso,mosi,slave_clk);
Slave UUT (.cs(cs) , .cpol(cpol) , .cpha(cpha) , .clk(slave_clk) , .mosi(mosi) , .miso(miso1) , .en_read(en_read) , .read(read) , .en_write(en_write) , .write(write) );
Slave UUT2 (.cs(cs2) , .cpol(cpol) , .cpha(cpha) , .clk(slave_clk) , .mosi(mosi) , .miso(miso2) , .en_read(en_read2) , .read(read2) , .en_write(en_write2) , .write(write2) );
Slave UUT3 (.cs(cs3) , .cpol(cpol) , .cpha(cpha) , .clk(slave_clk) , .mosi(mosi) , .miso(miso3) , .en_read(en_read3) , .read(read3) , .en_write(en_write3) , .write(write3) );
mux_4to1_case mis(miso1,miso2,miso3,1,choice,miso);
always
begin
#(period/2) clk = ~clk;
end

initial begin 
cpol=0;
cpha=0;
clk = 0;

reset=1;
start = 0;
$monitor( "slave in binary = %b slave2 in binary = %b slave3 in binary = %b master in binary = %b " ,read[7:0] ,read2[7:0] ,read3[7:0] , data_out[7:0] );
load = 0;
en_read =0;
en_write = 0;
en_read2 =0;
en_write2 = 0;
en_read3 =0;
en_write3 = 0;

#(period);//reset
reset=0;


#(period);
cs=0;
cs2=0;
cs3=0;

#(period);
en_write = 1;
en_write2 = 1;
en_write3 = 1;
write=8'b11111111;
write2=8'b11100100;
write3=8'b11110000;
#(period);
en_write = 0;
en_write2 = 0;
en_write3 = 0;
cs=1;
cs2=1;
cs3=1;

#(period);
cs=0;
choice=2'b00;

#(period);
start=1;

#(period);
start=0;

#(9*period);
en_read =1;

#(period);
en_read=0;
cs=1;

#(period);
cs2=0;
choice=2'b01;

#(period);
start=1;

#(period);
start=0;

#(9*period);
en_read2 =1;

#(period);
en_read2=0;
cs2=1;

#(period);
cs3=0;
choice=2'b10;

#(period);
start=1;

#(period);
start=0;

#(9*period);
en_read3 =1;

#(period);
en_read3=0;
cs3=1;

$finish;
end
endmodule

module mux_4to1_case ( input  a,                 // 4-bit input called a
                       input  b,                 // 4-bit input called b
                       input  c,                 // 4-bit input called c
                       input  d,                 // 4-bit input called d
                       input [1:0] sel,               // input sel used to select between a,b,c,d
                       output reg  out);         // 4-bit output based on input sel
 
   // This always block gets executed whenever a/b/c/d/sel changes value
   // When that happens, based on value in sel, output is assigned to either a/b/c/d
   always @ (a or b or c or d or sel) begin
      case (sel)
         2'b00 : out <= a;
         2'b01 : out <= b;
         2'b10 : out <= c;
         2'b11 : out <= d;
      endcase
   end
endmodule