import requests
from tzwhere import tzwhere
from datetime import datetime
from pytz import timezone

API_KEY = '4f6f8f30f593ed64cec14b81dd480eb2'


def mainFunc(zipCode):
	'''
		Takes in a zipcode, and returns the correct sequence of bits
	'''

	# get the weather dictionary
	weatherDict = getWeather(91711)
		
	# Run the final
	return setWeatherBits(weatherDict)

    
def getWeather(zipCode):

	zipCode = int(zipCode)

	# Create the parameters
	payload = {'zip': zipCode, 'APPID': API_KEY, 'units': "Imperial"}

	# Do the get request
	r = requests.get('http://api.openweathermap.org/data/2.5/weather', params=payload)

	# Conver the string version of dictionary to an actual dictionary
	dictionary = eval(r.text)
	# return the weather text
	return dictionary


def getCurrentTime(coordinates):

	# First, get the timezone in a location

	# set up tzwhere to get timezones
	tz = tzwhere.tzwhere()
	
	# Get the latitude and longitude out of the dictionary
	latitude = coordinates["lat"]
	longitude = coordinates["lon"]

	# Calculate the time zone
	tzResult = tz.tzNameAt(latitude, longitude)

	# Get the current UTC time
	currentTime = datetime.now(timezone(tzResult))

	return currentTime

def setWeatherBits(weatherDictionary):
	'''
		Takes in the weather information and sets the bits correctly
	'''
	# Set everything to 0 except our padding bits

	# First two bits = sunrise or sunset
	# Next 5 = brightness
	# Last = padding
	brightnessBits = [0, 0, 0, 0, 0, 0, 0, 1]

	# First bit is cloud
	# Second and third are precipitation (none/some/more/hella)
	# 1 bit if precipitation is rain or snow
	# 2 bits for lightning (none/some/more/hella)
	# 2 bits of padding
	weatherBits = [0, 0, 0, 0, 0, 0, 1, 1]

	# Entirely padding
	paddingBits = [1, 1, 1, 1, 1, 1, 1, 1]

	# Check to make sure we actually have data. If we don't, just return 0
	try:
		weatherDictionary["coord"]
	except KeyError:
		return 0

	# Get the time
	getCurrentTime(weatherDictionary["coord"])

	# Check weather conditions
	currentRain = 0
	currentSnow = 0
	for weatherCond in weatherDictionary['weather']:
		if 'rain' in weatherCond['main']:
			currentRain = 1
		if 'snow' in weatherCond['main']:
			currentSnow = 1

	finalArray = brightnessBits + weatherBits

	# Convert the bits to an integer, and send that
	intToReturn = convertBitsToInt(finalArray)

	return intToReturn


def convertBitsToInt(bitArray):
	'''
		Takes in a array of bits and converts it to a int
	'''
	finalResult = 0

	# Flip the list because it's in MSB order
	bitArray.reverse()

	# Loop through the array
	for i in range(len(bitArray)):

		# Add the bit * 2^i to our final result
		finalResult += ((2**i) * bitArray[i])

	return finalResult




