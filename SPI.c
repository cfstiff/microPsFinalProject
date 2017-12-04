#include "EasyPIO.h"


int main(){

	pioInit();
	pinMode(21,1);
	spiInit(250000, 0);

	printf("Beginning SPI\n");
int i = 1;
//while(i){
	digitalWrite(21,0);
	digitalWrite(21,1);

	spiSendReceive(0xB1);
	spiSendReceive(0xA3);
//	delayMicros(100);
	digitalWrite(21,0);
//	printf("Spi Done\n");
//}
	return 0;
}

