#include <Python.h>
#include "EasyPIO.h"

// Code from Python documentation with slight modifications

int getWeatherInt(char* zipCode, int brightness)
{
	// Make c actually import the pythonpath
setenv("PYTHONPATH", ".", 1);
    // Create the arguments
    int argc = 5;
    char** argv = (char**)malloc(sizeof(char*)*argc);
    argv[0] = "./apiCall";
    argv[1] = "apiCall";
    argv[2] = "mainFunc";
    argv[3] = zipCode;
	char str[10];
    sprintf(str, "%d", brightness);
    argv[4] = str;

    PyObject *pName, *pModule, *pDict, *pFunc;
    PyObject *pArgs, *pValue;
    int i;

    // Create a variable to store our output
    int outputVal = 0;

    if (argc < 3) {
        fprintf(stderr,"Usage: call pythonfile funcname [args]\n");
        return 1;
    }

     Py_Initialize();
    pName = PyUnicode_FromString(argv[1]);
    /* Error checking of pName left out */
    pModule = PyImport_Import(pName);
    Py_DECREF(pName);

    if (pModule != NULL) {
        pFunc = PyObject_GetAttrString(pModule, argv[2]);
        /* pFunc is a new reference */

        if (pFunc && PyCallable_Check(pFunc)) {
            pArgs = PyTuple_New(argc - 3);
            for (i = 0; i < argc - 3; ++i) {
                pValue = PyLong_FromLong(atoi(argv[i + 3]));
                if (!pValue) {
                    Py_DECREF(pArgs);
                    Py_DECREF(pModule);
                    fprintf(stderr, "Cannot convert argument\n");
                    return 1;
                }
                /* pValue reference stolen here: */
                PyTuple_SetItem(pArgs, i, pValue);
            }
            pValue = PyObject_CallObject(pFunc, pArgs);
            Py_DECREF(pArgs);
            if (pValue != NULL) {
                outputVal = PyLong_AsLong(pValue);
                Py_DECREF(pValue);
            }
            else {
                Py_DECREF(pFunc);
                Py_DECREF(pModule);
                PyErr_Print();
                fprintf(stderr,"Call failed\n");
                return 1;
            }
        }
        else {
            if (PyErr_Occurred())
                PyErr_Print();
            fprintf(stderr, "Cannot find function \"%s\"\n", argv[2]);
        }
        Py_XDECREF(pFunc);
        Py_DECREF(pModule);
    }
    else {
        PyErr_Print();
        fprintf(stderr, "Failed to load \"%s\"\n", argv[1]);
        return 1;
    }
    return outputVal;
}

void delayMinutes(int numMinutes){
    /*
        Takes in a number of minutes, and delays for that long
        Relies on underlying code in EasyPIO
    */

    // delay in milliseconds
    int delayInMillis = 6000 * numMinutes;

    delayMillis(delayInMillis);
}

int getUserBrightness(void){

	/*
	Opens a txt file to see what the user has set the brightness to
	Returns this as an integer
	*/
	FILE* brightnessFile;
	char buff[255];
	
	brightnessFile = fopen("brightness/brightness.txt", "r");
	if (brightnessFile != NULL)
	fscanf(brightnessFile, "%s", buff);
	else
{
	printf("file not opening");
	return 0; }
	return atoi(buff);
}

	

int main(){
    /*

    Runs a timer. Every so often, checks the weather, and then sends the bits over SPI

    */
    // We only need to initialize EasyPIO and SPI once
    pioInit();
    spiInit(250, 0);
    printf("Starting program \n");


   // Set up pins we need for SPI	
   pinMode(19, INPUT);
   pinMode(21, OUTPUT);
int i = 0;
    // While loop forever, because we want to constantly be checking
    while(i < 10){
      	 // Get the weather bits
	printf("loop ran\n");        
	int userBrightness = getUserBrightness();
	printf("User brightness is %d\n", userBrightness);	
	int weatherBitVal;
	// If the light is off, don't  get the weather
	if (digitalRead(19) == 0)
		weatherBitVal  = 0;
	else{
		// Get the weather bits
		int weatherBits = getWeatherInt("91711", userBrightness);
		// If the weather bits are 0, don't change them
		// Don't want to turn it off because of API errors
		if (weatherBits != 0)
		weatherBitVal = weatherBits;	
	/*

	DEMO MODE GOES HERE

	loop 0 = sunrise
	loop 1 = sunset
	loop 2 = low speed lightning and low speed rain
	loop 3 = high speed lightning and high speed snow
	AFTER LOOP 3 USE LIVE WEATHER DATA
	loop 4 = user defined brightness
	loop 5 = automatic brightness
	loop 6 = normal weather (turn the cloud off)
	loop 7 = normal weather (turn the cloud back on)

	*/
	if (i == 0){
		weatherBitVal = 48899;
	}
	else if (i == 1)
		weatherBitVal = 32515;
	else if (i == 2)
		weatherBitVal = 16167;
	else if (i == 3)
		weatherBitVal = 16255;

}
//	weatherBitVal = 43959;;
        printf("Bits have integer value of %d \n", weatherBitVal);
	printf("%d \n", weatherBitVal);
	i++;
	
	//Write our SPI enable pin high	
	digitalWrite(21, 1);
	// Send the relevant data
	spiSendReceive16(weatherBitVal);
	// Write the SPI enable pin low
	digitalWrite(21, 0);
	// Wait for some time before checking again
	printf("Delaying");
	delayMinutes(3);	
	printf("%d \n", i);
	    
}
// Stop the python interpreter
Py_Finalize();
printf("for loop done \n");



}

