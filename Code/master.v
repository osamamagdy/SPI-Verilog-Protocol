module master(
///////////////////// control of master working \\\\\\\\\\\\\\\\\\\\\\\\\\\\
    input       clk,
    input       reset,
    input       start,               // this is as a start command to start  
                                     // the communication

///////////////// input data and their verification \\\\\\\\\\\\\\\\\\\\\\\\\
    input[7:0]  data_in,
    input       load,                // one bit to tell the master to caputre
                                     // the data which coming on data in port

//////////////// output data and their verifiaction\\\\\\\\\\\\\\\\\\\\\\\\\\\
    output[7:0] data_out,            // data received on miso after the 
                                     // end of the communication
    output      busy,                // this an indicator of the 
                                     // transmission process
    output      data_out_received,   // this is an indicator of 
                                     // the completion of the transmission
                                     // process, so it will be 1 for one cycle
                                     // after the end of the transmission process 
    input       w_CPOL,
    input       w_CPHA,
  
///////////////////////////// interface \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
    input       miso,
    output      mosi,
    output      slave_clk

  );

// make a register copy of the output 
// so i can assign them in the always block
    
  
    reg [7:0]  reg_data_out;
    reg        reg_busy;
    reg        reg_data_out_received;
    reg        reg_mosi;
    reg        reg_miso;

    assign     data_out = reg_data_out;
    assign     busy = reg_busy;
    assign     data_out_received = reg_data_out_received;
    assign     mosi = reg_mosi;
   
    

// set values of w_CPOL and w_CPHA depending on the choosen mode  

    reg        reg_slave_clk; 
    assign     slave_clk = reg_slave_clk;

// two parameters to keep track with the data send and
// received so we can determine when the transmission ends
    reg[2:0]  Data_shifted_counter = 3'b000;  
    reg[2:0]  Data_sampled_counter = 3'b000;    
    reg[4:0]  sclk_edges_counter   = 5'b00000;
    reg[7:0]  local_shift_register;  
    reg       first_sample_done = 1'b0; 
    reg       sclk_first_edge = 1'b0;

always @(posedge clk or  negedge clk or posedge reset )   
   begin   // { 1
   if (reset == 1 )
       begin    // { 2
       reg_data_out <= 8'b00000000 ; 
       reg_data_out_received <=0 ;        
       local_shift_register = 8'b11111111;
       reg_busy = 1'b0;
       Data_sampled_counter = 3'b000;
       Data_shifted_counter = 3'b000;
       sclk_first_edge = 1'b0;
       first_sample_done = 1'b0; 
       reg_slave_clk = w_CPOL ;
       reg_mosi = local_shift_register[7];
       sclk_edges_counter   = 5'b00000;
       end  // } 2
   else 
       begin // { 3
       // this is the first clock edge 
       // and generate the second edge if the transmission 
       // didn't started in the first edge  

   
       if (sclk_edges_counter == 15 &  w_CPOL ==  w_CPHA )
           begin 
           reg_slave_clk = ~reg_slave_clk;   
           sclk_edges_counter = 0; 
           end

       if (sclk_edges_counter == 17 )
           begin 
           reg_slave_clk = ~reg_slave_clk;   
           sclk_edges_counter = 0; 
           end

       if (sclk_edges_counter > 0 & sclk_edges_counter < 17 )     
           begin      
           reg_slave_clk = ~reg_slave_clk;   
           sclk_edges_counter = sclk_edges_counter + 1;   
           end

       if (start == 1 & busy == 0 & sclk_first_edge == 0  & sclk_edges_counter == 0 )          
           begin
           reg_slave_clk = ~reg_slave_clk; 
           sclk_edges_counter = sclk_edges_counter + 1; 
           reg_data_out_received = 0;          
           end
       

       if (load ==1 & busy == 0)          
           local_shift_register = data_in; 
 
       if ( (reg_slave_clk == 1 & w_CPHA == 0)  |  ( reg_slave_clk == 0 &  w_CPHA == 1 ) ) // sample of data
          begin // { 5
          if (start == 1 & busy == 0) 
              begin
              sclk_first_edge = 1'b1;
              first_sample_done = 1'b1; 
	      reg_busy = 1'b1;	       
	      reg_miso = miso;
	      Data_sampled_counter = Data_sampled_counter + 1 ;
	      end	        
          else if ( Data_sampled_counter < 7 & Data_sampled_counter > 0)
	      begin	       
	      reg_miso = miso;
	      Data_sampled_counter = Data_sampled_counter + 1 ;               
	      end	
          else if (Data_sampled_counter == 7)
	      begin         	      
	      reg_miso = miso;
	      Data_sampled_counter = 3'b000;                
	      end
         end  // } 5

     else if ( (reg_slave_clk == 0 & w_CPHA == 0 )  |  ( reg_slave_clk == 1 &  w_CPHA == 1 ) )// clk == trailling edge  // data must be shifted out here
         begin  // { 6
         
         if (first_sample_done == 1 & Data_shifted_counter==0)
             begin // { 7 
             local_shift_register  = { local_shift_register [6:0] ,reg_miso};	        
             reg_mosi = local_shift_register[6];
	     Data_shifted_counter = Data_shifted_counter + 1 ;                                   
	     end            
         else if ( Data_shifted_counter < 7 &  Data_shifted_counter > 0 )
             begin
	     local_shift_register  <= { local_shift_register [6:0] ,reg_miso};	        
             reg_mosi = local_shift_register[6];
	     Data_shifted_counter = Data_shifted_counter + 1 ;
 	     first_sample_done = 0;                                 
	     end	
         else if (Data_shifted_counter == 7)
             begin           
             local_shift_register  = { local_shift_register [6:0] ,reg_miso};	          
             Data_shifted_counter = 3'b000 ; 
             reg_busy = 0;
             reg_data_out_received =1;
             reg_data_out = local_shift_register;    
	     sclk_first_edge=0;
             reg_mosi = local_shift_register[7];     
	     end
	      // } 7
          end  // } 6
       end  // } 3
   end // } 1
       
endmodule

module master_tb();

reg  clk;
reg  reset;
reg  start;
reg  [7:0] data_in;
reg  load;
reg  miso;
wire [7:0] data_out;
wire busy;
wire data_out_received;
wire mosi;
wire slave_clk;
reg  CPOL;
reg  CPHA;
reg  [7:0] slave  = 8'b11111000;
reg  [7:0] slave1 = 8'b00000000;
reg  [7:0] slave2 = 8'b00000000;
reg  [7:0] slave3 = 8'b00000000;
reg  [7:0] slave4 = 8'b00000000;
reg  [7:0] indata = 8'b10101010;
reg  [7:0] data_in_master = 8'b11111111;
spi   medo(clk,reset,start,data_in,load,data_out,busy,data_out_received,CPOL,CPHA,miso,mosi,slave_clk);

integer i;

localparam period = 10;

always
begin
#(period/2) clk = ~clk;
end

initial begin 

//$monitor( "slave in binary = %b slave1 in binary = %b slave2 in binary = %b slave3 in binary = %b slave4 in binary = %b  data_sent in binary = %b " ,data_in_master[7:0] ,slave1[7:0],slave2[7:0],slave3[7:0],slave4[7:0] , data_out[7:0] );
$display(" >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<");
$display(" >>>>>>>>>>>>>>>>>>>>>>>>>>>>>> Mode 0 <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<");
$display(" >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<");
$display(" Data in salve     Data get from Master after transmission");
$monitor("   %b                    %b ",slave1[7:0], data_out[7:0] );
///////////////////////////////////// test form mode 0 \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\ 
CPOL = 0;
CPHA = 0;
clk = 0;
reset=1;
start = 0;
load = 0;
# ( period );
start = 1;
reset= 0;
clk = 1 ;
for (i = 7 ; i >= 0 ; i=i-1)
begin 
miso = indata[i];  
#(5*period/10);
slave1[i] = mosi;
#(5*period/10);
if (i == 5)
start = 0;
end
#(2*period);
if (data_in_master == slave1 & indata == data_out )
$display(" >>>>>>>> Check done ==> transmmison done correctly in mode 0 <<<<<<<<");
///////////////////////////////////// test form mode 1 \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\ 
$display(" >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<");
$display(" >>>>>>>>>>>>>>>>>>>>>>>>>>>>>> Mode 1 <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<");
$display(" >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<");
$display(" Data in salve     Data get from Master after transmission");
$monitor("   %b                    %b ",slave2[7:0], data_out[7:0] );
CPOL = 0;
CPHA = 1;
clk = 0;
reset=1;
start = 0;
load = 0;
# (15* period / 10 );
start = 1;
reset= 0;
clk = 1 ;
for (i = 7 ; i >= 0 ; i=i-1)
begin 
miso = indata[i]; 
slave2[i] = mosi; 
#(period);
if (i == 5)
start = 0;
end
#(2*period);
if (data_in_master == slave2 & indata == data_out )
$display(" >>>>>>>> Check done ==> transmmison done correctly in mode 1 <<<<<<<<");
///////////////////////////////////// test form mode 2 \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\ 
$display(" >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<");
$display(" >>>>>>>>>>>>>>>>>>>>>>>>>>>>>> Mode 2 <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<");
$display(" >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<");
$display(" Data in salve     Data get from Master after transmission");
$monitor("   %b                    %b ",slave3[7:0], data_out[7:0] );
CPOL = 1;
CPHA = 1;
clk = 0;
reset=1;
start = 0;
load = 0;
# (15 * period / 10);
start = 1;
reset= 0;
clk = 1 ;
for (i = 7 ; i >= 0 ; i=i-1)
begin 
miso = indata[i];
#(5 * period / 10);
slave3[i] = mosi; 
#(5 * period / 10);
if (i == 5)
start = 0;
end
#(2*period);
if (data_in_master == slave3 & indata == data_out )
$display(" >>>>>>>> Check done ==> transmmison done correctly in mode 2 <<<<<<<<");
///////////////////////////////////// test form mode 3 \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\ 
$display(" >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<");
$display(" >>>>>>>>>>>>>>>>>>>>>>>>>>>>>> Mode 3 <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<");
$display(" >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<");
$display(" Data in salve     Data get from Master after transmission");
$monitor("   %b                    %b ",slave4[7:0], data_out[7:0] );
CPOL = 1;
CPHA = 0;
clk = 0;
reset=1;
start = 0;
load = 0;
#(15 * period / 10);
start = 1;
reset= 0;
clk = 1 ;
for (i = 7 ; i >= 0 ; i=i-1)
begin 
miso = indata[i]; 
#( 5 * period / 10);
slave4[i] = mosi; 
#( 5 * period / 10);
if (i == 5)
start = 0;
end
#(2*period);
if (data_in_master == slave4 & indata == data_out )
$display(" >>>>>>>> Check done ==> transmmison done correctly in mode 4 <<<<<<<<");
$stop;
end
endmodule