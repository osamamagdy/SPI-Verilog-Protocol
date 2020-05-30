module Slave ( cs , cpol , cpha , clk , mosi , miso , en_read , read , en_write , write );
//////////Read me
//ans that the testbench will read the register
//////////Write means the register will take the data and store it

input cs, cpol, cpha, clk, mosi , en_read , en_write;
input [7 : 0] write;
output wire miso ;
output reg [7 : 0] read ;
reg [7 : 0] data;
reg miso_temp;
reg mosi_temp;
reg [4:0] edges_counter = 0 ; 
reg first_sample_done = 0 ;
assign  miso = miso_temp ;

reg ziad=0;

always @ (posedge clk , en_read , en_write)
begin
//////////Every single Condition is anded with ch to be low (active low chip select)
	if (clk & ~en_read & ~en_write & ~cs )
	begin
		if (~cpha) 
	////////// If cpha is 0, this means at the rising edge we sample data for both master and slave.
	////////// So we store the coming data in a temporary register from the mosi
	////////// And we write the data for the miso line from the miso temporary register
			begin
				mosi_temp = mosi;				
				ziad=1;
			        first_sample_done = 1;
                                edges_counter = edges_counter + 1 ;	
			end
		else if (edges_counter > 0 & first_sample_done == 1)
	//////////Similarly, If cpha is 1, this means at the rising edge we shift data for both master and slave.
	////////// So we mainly deal with the temporary register whether to write or read from them
	////////// We first store the MSB in the miso in case the master tries to read it
	///////// After that we shift data to the right and make the LSB is the data stored in the mosi register
	
			begin 
				if(ziad==1)
				begin
                                        
					miso_temp = data[6];
                                        data = { data[6:0] , mosi_temp };					
                                        edges_counter = edges_counter + 1 ;
				end
                                if (edges_counter == 16)
                                    begin
                                    edges_counter = 0;
                                    first_sample_done = 0 ;
                                    end
			end
	end

	else if (en_write & ~cs )
//////////Write means the register will take the data and store it

	begin
		data = write;
                miso_temp = data[7];
	end

	else if (en_read & ~cs)
//////////Read means that the testbench will read the register

	begin
		read = data;
	end

	else 
	begin
	end


end


always @ (negedge clk  , en_read , en_write)
begin
	if (~clk & ~en_read & ~en_write & ~cs)
	begin
		if (cpha)
	////////// If cpha is 1, this means at the falling edge we sample data for both master and slave.
	////////// So we store the coming data in a temporary register from the mosi
	////////// And we write the data for the miso line from the miso temporary register

			begin
				mosi_temp = mosi;				
				ziad=1;
                                edges_counter = edges_counter +1 ;
                                first_sample_done = 1 ;
			end
		else if(edges_counter > 0 & first_sample_done == 1)
	//////////Similarly, If cpha is 0, this means at the falling edge we shift data for both master and slave.
	////////// So we mainly deal with the temporary register whether to write or read from them
	////////// We first store the MSB in the miso in case the master tries to read it
	///////// After that we shift data to the right and make the LSB is the data stored in the mosi register

			begin 				
				if(ziad==1)
				begin
					miso_temp = data[6];
                                        data = { data[6:0] , mosi_temp };					
                                        edges_counter = edges_counter + 1 ;
				end
                                 if (edges_counter == 16)
                                    begin
                                    edges_counter = 0;
                                    first_sample_done = 0 ;
                                    end
			end
	end


	else if (en_write & ~cs )
//////////Write means the register will take the data and store it

	begin
		data = write;
                miso_temp = data[7];
	end

	else if (en_read & ~cs)
//////////Read means that the testbench will read the register

	begin
		read = data;
               
	end
	
	else 
	begin
	end
end

endmodule








////////////////////////////////////////////////

module Slave_tb ();


reg flag , cs , cpol , cpha , clk , mosi , en_read , en_write ;
reg [7 : 0] write;
wire miso;
wire [7 : 0] read ;
reg [7:0] test_in;
reg [7:0] test_out;
localparam PERIOD = 10 ;

Slave UUT (.cs(cs) , .cpol(cpol) , .cpha(cpha) , .clk(clk) , .mosi(mosi) , .miso(miso) , .en_read(en_read) , .read(read) , .en_write(en_write) , .write(write) );
integer i,j;
initial 
begin

$monitor ("At time = %g, the chip select is: %b , CPOL = %b , CPHA = %b, clk = %b, MOSI = %b, MISO = %b, en_read = %b, Data in the register= %b , en_write= %b , data we pass to the register =%b ,test_in = %b and test_out =%b " , $time , cs , cpol , cpha , clk , mosi , miso , en_read , read , en_write , write , test_in , test_out );
cs = 0 ;
cpol = 0;
cpha = 0;
clk = 0 ;
test_in = 8'b11000000;
test_out = 8'b00000000;
en_read =0;
en_write = 0;
#PERIOD ;

//////////////////Test cpha = 0 ///////////////////////////

	$display ("This Test is for the cpha =%b" , cpha);


////////Testing writing on mosi only using external read register///////////
for (i=7 ; i>= 0 ; i=i-1)
	begin
		clk = 1 ;
		mosi = test_in[i];
		#PERIOD;
		clk = 0 ;
		#PERIOD;
	end

en_read = 1;
#PERIOD;
if (read == test_in)
	$display ("Identical results for the test_in");

#PERIOD;
en_read = 0 ;



////////Testing reading from miso only using external write register///////////
en_write = 1;
write = 8'b11001010;
#PERIOD;
en_write = 0 ;
#PERIOD;
clk = 0;
#PERIOD;
for (i=7 ; i>= 0 ; i=i-1)
	begin
		clk = 1 ;
		#PERIOD;
		test_out[i] = miso;
		clk = 0 ;
		#PERIOD;
	end
#PERIOD;
if (test_out == write)
	$display ("Identical results for the test_out");

#PERIOD;




//////////////////Testing the data transmition between miso and mosi together /////////////////
en_read =0;
en_write = 0;
#PERIOD ;
for (i=7 ; i>= 0 ; i=i-1)
	begin
		clk = 1 ;
		mosi = test_in[i];
		#PERIOD;
		clk = 0 ;
		#PERIOD;
	end

/*clk = 1 ;
#PERIOD;
clk=0;
#PERIOD;*/


for (i=7 ; i>= 0 ; i=i-1)
	begin
		clk = 1 ;
		#PERIOD;
		test_out[i] = miso;
		clk = 0 ;
		#PERIOD;
	end

if(test_out == test_in)
	$display ("We get the same data on both test_out and test_in");



///////////////////////////////////////Test cpha = 1 /////////////////////

cpha=1;
clk = 1;

#PERIOD ;



	$display ("This Test is for the cpha =%b" , cpha);


////////Testing writing on mosi only using external read register///////////
for (i=7 ; i>= 0 ; i=i-1)
	begin
		clk = 0 ;
		mosi = test_in[i];
		#PERIOD;
		clk = 1 ;
		#PERIOD;
	end

en_read = 1;
#PERIOD;
if (read == test_in)
	$display ("Identical results for the test_in");

#PERIOD;
en_read = 0 ;



////////Testing reading from miso only using external write register///////////
en_write = 1;
write = 8'b11001010;
#PERIOD;
en_write = 0 ;
#PERIOD;
clk = 1;
#PERIOD;
for (i=7 ; i>= 0 ; i=i-1)
	begin
		clk = 0 ;
		#PERIOD;
		test_out[i] = miso;
		clk = 1 ;
		#PERIOD;
	end
#PERIOD;
if (test_out == write)
	$display ("Identical results for the test_out");

#PERIOD;




//////////////////Testing the data transmition between miso and mosi together /////////////////
en_read =0;
en_write = 0;
#PERIOD ;
for (i=7 ; i>= 0 ; i=i-1)
	begin
		clk = 0 ;
		mosi = test_in[i];
		#PERIOD;
		clk = 1 ;
		#PERIOD;
	end
/*
clk = 0 ;
#PERIOD;
clk=1;
#PERIOD;
*/

for (i=7 ; i>= 0 ; i=i-1)
	begin
		clk = 0 ;
		#PERIOD;
		test_out[i] = miso;
		clk = 1 ;
		#PERIOD;
	end

if(test_out == test_in)
	$display ("We get the same data on both test_out and test_in");

















end


endmodule
