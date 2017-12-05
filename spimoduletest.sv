module paramcounter #(parameter N)
				(input logic clk,
				input logic reset,
				output logic [N-1:0]q);
// basic parameterized counter			
		always_ff @(posedge clk, posedge reset)
			if (reset) q<= 0;
			else q<=q+1;
endmodule

/*module paramspi #(parameter N)(input logic clk,
					input logic sck,
					output logic mosi,
					input logic [N-1:0]datain);
logic[N-1:0]p;//=160'b0;
logic [9:0]count;
assign mosi = datain[N-count-1];
	
always_ff @(posedge sck)
	if(count < N-1)
		count = count + 1;
	
endmodule
*/



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
module rain (input logic clk,
						input logic sck,
						input logic [4:0]globalbrightness,
						input logic [7:0]blue,
						input logic [7:0]green,
						input logic [7:0]red,
						input logic [1:0]speed,
						output logic mosi);
// create slow clock- constrained by time to control entire strand via spi (load clock)
logic [29:0]slockcount;						
paramcounter #(30) slockmake(clk, 1'b0, slockcount);
logic slock;

assign slock = slockcount[22-speed];

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


module raincontroller(input logic clk,
						input logic sck,
						input logic raen,
						input logic [4:0]globalbrightness,
						input logic [7:0]blue,
						input logic [7:0]green,
						input logic [7:0]red,
						input logic [1:0]speed,
						output logic mosirain1,
						output logic mosirain2,
						output logic mosirain3);
						
logic [4:0] rainbrightness;
assign rainbrightness = (raen==0)? 5'b00000 : globalbrightness;						



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


module spi_slave_receive_only(input logic pien,
										input logic pisck, //From master
										input logic pimosi,//From master
										output logic [15:0] data); // Data received
logic [15:0] q;
always_ff @(posedge pisck)
begin
	q<={q[14:0],pimosi};
end
	
always_ff @(negedge pien)
	data <= q;
endmodule



module fakespi(input clk,
					output [0:15]spiout);
assign spiout = 16'b10101010__10101010; //16'b01_11111_1__0_01_1_00_11; 
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
							input logic pimosi,
							input logic pisck,
							input logic pien,
							input logic pispienable,
							output logic sckout,
							output logic sckout2,
							output logic sckout3,
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
parameter sckN = 30;
logic [sckN-1:0]counter;						
paramcounter #(sckN) sckmake(clk, reset, counter);
assign sck = counter[6];

// sets clock output pins
assign sckout = sck;
assign sckout2 = sck;
assign sckout3 = sck;

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

logic [15:0] spiout;
//assign spiout = 16'b01_11111_1__0_00_1_00_11; 
spi_slave_receive_only inittest(pien,pisck, pimosi,spiout);

logic [7:0]lred;
logic [7:0]lblue;
logic [7:0]lgreen;
logic [7:0]lred1;
logic [7:0]lblue1;
logic [7:0]lgreen1;
logic [7:0]lred2;
logic [7:0]lblue2;
logic [7:0]lgreen2;
logic [7:0]lred3;
logic [7:0]lblue3;
logic [7:0]lgreen3;
logic [7:0]rred;
logic [7:0]rblue;
logic [7:0]rgreen;

logic [4:0]globalbrightness,rainbrightness,lanternbrightness;
assign globalbrightness = spiout[13:9];

logic [1:0]speed, lightning;
assign speed = spiout[6:5];
assign lightning = spiout[3:2];

logic sunrise,sunset, cloud, rainsnow;
assign sunrise = spiout[15];
assign sunset = spiout[14];
assign cloud = spiout[7];
//rain if 1, snow if 0
assign rainsnow = spiout[4];
						

						
always_ff @(posedge sck)
begin
	if(lightning == 2'b01)
		begin
			if((counter[29:26] == 4'b1111)&(counter[23]^counter[24]^counter[22]))
			begin
				lanternbrightness = 5'b00000;
			end
			else
				lanternbrightness = globalbrightness;
		end
	else if (lightning == 2'b10)
		begin
			if((counter[29:27] == 3'b111)&(counter[23]^counter[24]^counter[22]))
			begin
				lanternbrightness = 5'b00000;
			end
			else
				lanternbrightness = globalbrightness;
		end
	else if (lightning == 2'b11)
		begin
			if((counter[29:27] == 3'b111 | counter[29:27] == 3'b011)&(counter[23]^counter[24]^counter[22]))
			begin
				lanternbrightness = 5'b00000;
			end
			else
				lanternbrightness = globalbrightness;
		end
	else lanternbrightness = globalbrightness;
	
	if(sunrise)
		begin
			 lred1 = 8'hFF;
			 lblue1 = 8'h00;
			 lgreen1 = 8'h32;
			 lred2 = 8'hFF;
			 lblue2 = 8'hAA;
			 lgreen2 = 8'h00;
			 lred3 = 8'hFF;
			 lblue3 = 8'h00;
			 lgreen3 = 8'h52;
		end
	else if(sunset)
		begin
			 lred1 = 8'hFF;
			 lblue1 = 8'hAA;
			 lgreen1 = 8'h00;
			 lred2 = 8'hFF;
			 lblue2 = 8'h00;
			 lgreen2 = 8'h32;
			 lred3 = 8'hFF;
			 lblue3 = 8'h99;
			 lgreen3 = 8'h00;
		end
	else if(!sunrise && !sunset)
		begin
			lred1 = 8'hFF;
			 lblue1 = 8'hFF;
			 lgreen1 = 8'hFF;
			 lred2 = lred1;
			 lblue2 = lblue1;
			 lgreen2 = lgreen1;
			 lred3 = lred1;
			 lblue3 = lblue1;
			 lgreen3 = lgreen1;
		end
	
	if(!rainsnow)
		begin
			rred = 8'hFF;
			rblue = 8'hFF;
			rgreen = 8'hFF;
		end
	else if(rainsnow)
		begin
			rred = 8'h00;
			rblue = 8'hFF;
			rgreen = 8'h00;
		end
		
		
	if(speed==0)
		rainbrightness = 5'b00000;
	else if(speed != 0)
		rainbrightness = globalbrightness;
end

// assigns lanterns different dawn colors
// generate outputs
logic [largb-1:0]datainlarg;
valueGenOneColor #(larglen) orangetest(globalbrightness,lblue1,lgreen1,lred1,datainlarg);
logic [medb-1:0]datainmed;
valueGenOneColor #(medlen) bluetest(lanternbrightness,lblue2,lgreen2,lred2,datainmed);
logic [smalb-1:0]datainsmal;
valueGenOneColor #(smallen) pinktest(globalbrightness,lblue3,lgreen3,lred3,datainsmal);


// do the spi
paramspi #(largb) bigstrand(clk,sck,mosilarg,datainlarg);
paramspi #(medb) medstrand(clk,sck,mosimed,datainmed);
paramspi #(smalb) smalstrand(clk,sck,mosismal,datainsmal);

// controls three rain strands
rain createrain(clk,sck, rainbrightness,rblue,rgreen,rred,speed,mosirain1);
rain rain2constructor(clk,sck, rainbrightness,rblue,rgreen,rred,speed,mosirain2);
rain rain3constructor(clk,sck, rainbrightness,rblue,rgreen,rred,speed,mosirain3);

endmodule
