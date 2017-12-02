module paramcounter #(parameter N)
				(input logic clk,
				input logic reset,
				output logic [N-1:0]q);
// basic parameterized counter			
		always_ff @(posedge clk, posedge reset)
			if (reset) q<= 0;
			else q<=q+1;
endmodule

module paramspi #(parameter N)(input logic clk,
					input logic sck,
					output logic mosi,
					input logic [N-1:0]datain);
logic[N-1:0]p=0;//=160'b0;
logic[25:0]counter;
paramcounter #(26) loadclk(clk,1'b0,counter);
logic load;
// load clock calculated to take slightly longer than SPI for 512 bits
assign load = counter[16];
assign mosi = p[N-1];
always_ff @(posedge sck)
		if(load)
			p<=datain;
		else p<= {p[N-2:0],1'b0};
// p is filled with zeros as they don’t change the LED actions
endmodule

// makes an led strand simulate rain
// rain strands are either 10 or 12
// commanding a strand of 10 leds with the information for 12 doesn’t cause errors, so assume a length of 12 leds for all rain commands
// rain will probably always be white, but it can take any color input
module rain #(parameter speed)(input logic clk,
						input logic sck,
						input logic [4:0]globalbrightness,
						input logic [7:0]blue,
						input logic [7:0]green,
						input logic [7:0]red,
						output logic mosi);
// create slow clock- constrained by time to control entire strand via spi (load clock)
logic [29:0]slockcount;						
paramcounter #(30) slockmake(clk, 1'b0, slockcount);
logic slock;

assign slock = slockcount[speed+19];

// raininstance is the dataout sent to the led strand, ledpattern is the on/off pattern (12 bits, 1 on, 0 off)
logic [0:11]ledpattern;

logic[14*32-1:0]raininstance;
generateRainInstance eachrain(ledpattern, globalbrightness, blue, green, red, raininstance);											
paramspi #(14*32) testled(clk,sck,mosi,raininstance);

// rotates led pattern- the two modules above will be called again every time ledpattern changes
always_ff @(posedge slock)
	begin
		if(ledpattern == 12'b000000000000)
			ledpattern <= 12'b100000000000;
		else 
			ledpattern <= ledpattern >> 1;
	end
endmodule

// uses ledpattern to create the spi output for an individual moment of rain
module generateRainInstance(
						input logic [0:11]ledpattern,
						input logic [4:0]globalbrightness,
						input logic [7:0]blue,
						input logic [7:0]green,
						input logic [7:0]red,
						output logic[0:14*32-1]ledstring);
// constants based on datasheet
logic[31:0]startbits;
logic[31:0]endbits;
logic[31:0]ledbits;
logic[31:0]offled;
assign offled = 32'hE0000000;
assign startbits = 32'b0;
assign endbits = 32'hFFFFFFFF;
assign ledbits = {3'b111,globalbrightness,blue,green,red};

// assigns each part of ledstring bitwise (this is why the length is constant)
assign ledstring[0:31] = startbits;
assign ledstring[32*1:32*2-1] = (ledpattern[0] == 1)? ledbits : offled;
assign ledstring[32*2:32*3-1] = (ledpattern[1] == 1)? ledbits : offled;
assign ledstring[32*3:32*4-1] = (ledpattern[2] == 1)? ledbits : offled;
assign ledstring[32*4:32*5-1] = (ledpattern[3] == 1)? ledbits : offled;
assign ledstring[32*5:32*6-1] = (ledpattern[4] == 1)? ledbits : offled;
assign ledstring[32*6:32*7-1] = (ledpattern[5] == 1)? ledbits : offled;
assign ledstring[32*7:32*8-1] = (ledpattern[6] == 1)? ledbits : offled;
assign ledstring[32*8:32*9-1] = (ledpattern[7] == 1)? ledbits : offled;
assign ledstring[32*9:32*10-1] = (ledpattern[8] == 1)? ledbits : offled;
assign ledstring[32*10:32*11-1] = (ledpattern[9] == 1)? ledbits : offled;
assign ledstring[32*11:32*12-1] = (ledpattern[10] == 1)? ledbits : offled;
assign ledstring[32*12:32*13-1] = (ledpattern[11] == 1)? ledbits : offled;
assign ledstring[32*13:32*14-1] = endbits;
						
endmodule
	
						
// create the SPI output to turn a led with numleds a singled color as input
module  valueGenOneColor#(parameter numleds)(
						input logic [4:0]globalbrightness,
						input logic [7:0]blue,
						input logic [7:0]green,
						input logic [7:0]red,
output logic[0:((numleds+2)*32)-1]ledstring);
logic[31:0]startbits;
logic[31:0]endbits;
logic[31:0]ledbits;
assign startbits = 32'b0;
assign endbits = 32'hFFFFFFFF;
assign ledbits = {3'b111,globalbrightness,blue,green,red};

// {m{n}} replicates n m times
assign ledstring = {startbits, {numleds{ledbits}}, endbits};
endmodule				
		
		
module spimoduletest(input logic clk,
							output logic sckout,
							output logic sckout2,
							output logic sckout3,
							output logic sckout4,
							output logic mosilarg,
							output logic mosimed,
							output logic mosismal,
							output logic mosirain1,
							output logic mosirain2,
							output logic mosirain3);
// reset, enable, and slow clock for led SPIs
logic reset, sck;
assign reset = 1'b0;

// bit size of sck clock counter
parameter sckN = 26;
logic [sckN-1:0]counter;						
paramcounter #(sckN) sckmake(clk, reset, counter);
assign sck = counter[6];

// sets clock output pins
assign sckout = sck;
assign sckout2 = sck;
assign sckout3 = sck;
assign sckout4 = sck;

// this ends up not being used, will be deleted soon

// we have the following LED strands (followed by length)
// largest(14), medium(6), smalls(6), rain1(10), rain2(12), rain3(12)
// parameter constants of number of leds, followed by bit length
parameter larglen = 14;
parameter largb = ((larglen+2)*32);
parameter medlen = 6;
parameter medb = ((medlen+2)*32);
parameter smallen = 6;
parameter smalb = ((smallen+2)*32);
parameter rain1len = 10;
parameter rain1b = ((rain1len+2)*32);
parameter rain2len = 12;
parameter rain2b = ((rain2len+2)*32);
parameter rain3len = 12;
parameter rain3b = ((rain3len+2)*32);

// test bit string
//assign datain = 512'h00000000_FF0000FF_FF0000FF_FF0000FF_FF0000FF_FF0000FF_FF0000FF_FF0000FF_FF0000FF_FF0000FF_FF0000FF_FF0000FF_FF0000FF_FFFF0000_FFFF00FF_FFFFFFFF;

// assigns lanterns different dawn colors
// generate outputs
logic [largb-1:0]datainlarg;
valueGenOneColor #(larglen) orangetest(5'b11000,8'h42,8'h7A,8'hF4,datainlarg);
logic [medb-1:0]datainmed;
valueGenOneColor #(medlen) bluetest(5'b11000,8'h00,8'h50,8'hFF,datainmed);
logic [smalb-1:0]datainsmal;
valueGenOneColor #(smallen) pinktest(5'b11000,8'h00,8'h64,8'hDB,datainsmal);
// do the spi
paramspi #(largb) bigstrand(clk,sck,mosilarg,datainlarg);
paramspi #(medb) medstrand(clk,sck,mosimed,datainmed);
paramspi #(smalb) smalstrand(clk,sck,mosismal,datainsmal);

// controls three rain strands
rain #(0) createrain(clk,sck, 5'b11000, 8'hFF,8'hFF,8'hFF, mosirain1);
rain #(1) rain2constructor(clk,sck, 5'b11000,8'hFF,8'hFF,8'hFF,mosirain2);
rain #(2) rain3constructor(clk,sck,5'b11000,8'hFF,8'hFF,8'hFF,mosirain3);


// individual rain command test
/*logic[rain2b-1:0]testraindata;
generateRainInstance whitetest(12'b100000100001, 5'b11111,8'hFF,8'hFF,8'hFF,testraindata);
paramspi #(rain2b) testled(clk,sck,mosib,testraindata);*/

// basic shift register test
/*logic [159:0]datain = 160'h00000000_FF0000FF_FF0000FF_FF0000FF_FFFFFFFF;
assign mosia = datain[159];
always_ff @(posedge sck)
		datain <= {datain[158:0], 1'b0};*/
endmodule
