#include <stdio.h>


int main(void){
	
	// Print the HTML header
	printf("%s%c%c\n", "Content-Type:text/html;charset=iso-8859-1",13,10);
	
	// Get our brightness value from the QUERY_STRING value
	const char* brightnessValue = getenv("QUERY_STRING");
//	const char* brightnessValue = "brightness=23";	
	// Get a pointer to the equal sign
	char* arg  = strchr(brightnessValue, '=');
	 
	// Check if the value is null
	if (brightnessValue == NULL){
		printf("Sorry, brightness value cannot be read");
	}
	

	// If not, write the brightness value out to a text file
	else{
		FILE* brightnessFile;
		const char* filename = "/home/pi/Desktop/FinalProject/microPsFinalProject/brightness/brightness.txt";
		const char* mode = "w";
		brightnessFile = fopen(filename, mode);

		// Write out the brightness
		if (brightnessFile != NULL){
			// Only  write characters after the equal sign 
			arg++;
			printf("%c\n", *arg);
			while (*arg)
			{
//				arg++;
				printf("%c\n", *arg);
				fputc(*arg, brightnessFile);
				++arg;
}	
			// Close the file
			fclose(brightnessFile);
			// Redirect back to the homepage
			printf("<META HTTP-EQUIV=\"Refresh\" CONTENT=\"0;url=/cloud.html\">");
		}
		// If we can't open the file, display an error
		else{
			printf("error saving to file");
}}
	return 0;

}

