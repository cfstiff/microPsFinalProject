//#include "apiCallSpi.h"
#include "EasyPIO.h"

// Define the global variable 
//int globalCloudToggle;

int main(void){

	// Initialize EasyPIO
	pioInit();

	// Set up pin 21 to write
	pinMode(13, OUTPUT);

	// Write high to the pin
	digitalWrite(13, 1);
	
	// Print the HTML header
	printf("%s%c%c\n", "Content-Type:text/html;charset=iso-8859-1",13,10);

	// Redirect back to main page
	printf("<META HHTP-EQUIV=\"Refresh\" CONTENT=\"0;url=/cloud.html\">");

	return 0;

}
