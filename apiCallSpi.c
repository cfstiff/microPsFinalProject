#include <Python/Python.h>
#include "EasyPIO.h"

// Code from Python documentation with slight modifications

int getWeatherInt()
{
    // Create the arguments
    int argc = 4;
    char** argv = (char**)malloc(sizeof(char*)*argc);
    argv[0] = "./apiCall";
    argv[1] = "apiCall";
    argv[2] = "main";
    argv[3] = "91711";
    
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
    Py_Finalize();
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



int main(){
    /*

    Runs a timer. Every 15 minutes, checks the weather, and then sends the bits over SPI

    */
    // We only need to initialize EasyPIO and SPI once
    pioInit();
    spiInit(250, 0);

    printf("Starting program \n");

    // While loop forever, because we want to constantly be checking
    while(1){
        // Get the weather bits
        int weatherBitVal = getWeatherInt();

        printf("Bits have integer value of %d \n", weatherBitVal);

        // Wait for 2 minutes
        delayMinutes(2);
    }



}

