import requests
from tzwhere import tzwhere
from datetime import datetime, timedelta
from pytz import timezone
import pytz

API_KEY = '4f6f8f30f593ed64cec14b81dd480eb2'


def mainFunc(zipCode):
	'''
		Takes in a zipcode, and returns the correct sequence of bits
	'''

	# get the weather dictionary
	weatherDict = getWeather(zipCode)
		
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

	print(dictionary)
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

	currentTime = currentTime.replace(tzinfo = None)

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

	# First bit is 0 cause we don't have anything to put here
	# Second and third are precipitation (none/some/more/hella)
	# 1 bit if precipitation is rain or snow (rain = 0)
	# 2 bits for lightning (none/some/more/hella)
	# 2 bits of padding
	weatherBits = [0, 0, 0, 0, 0, 0, 1, 1]

	# Entirely padding
	paddingBits = [0, 0, 0, 0, 0, 0, 0, 0]

	# Check to make sure we actually have data. If we don't, just return 0
	try:
		weatherDictionary["coord"]
	except KeyError:
		return 0

	# Get the time
	currentTime = getCurrentTime(weatherDictionary["coord"])

	#########################
	#  SUNSET/SUNRISE/TIME  #
	#########################

	# Get the time for sunrise and sunset
	sunrise =  datetime.fromtimestamp(
        weatherDictionary['sys']['sunrise'])
	sunset =  datetime.fromtimestamp(
        weatherDictionary['sys']['sunset'])

	# Calculate the amount of time until sunrise and sunset
	timeToSunrise = abs(currentTime - sunrise)
	timeToSunset = abs(currentTime - sunset)

	# Create a time delta of 30 minutes
	previousTimeDelta = timedelta(minutes = 30)



	# Check if we are within 30 minutes of the sunrise
	if currentTime >= sunrise - previousTimeDelta and currentTime <= sunrise - previousTimeDelta:
		# If we are, set sunrise bits to 1
		brightnessBits[0] = 1

	elif currentTime >= sunset - previousTimeDelta and currentTime <= sunset - previousTimeDelta:
		brightnessBits[1] = 1


	#####################################
	#		RAIN/LIGHTNING/CLOUDS		#
	#####################################

	# Check weather conditions
	for weatherCond in weatherDictionary['weather']:

		description = weatherCond['description']

		# RAIN
		if 'rain' in weatherCond['main']:
			# set weather bit to 0
			weatherBits[3] = 0
			# Check how much rain there is
			if description == "light rain" or description == "light intensity shower rain":
				weatherBits[1:3] = [0, 1]
			elif description == "moderate rain" or description == "shower rain":
				weatherBits[1:3] = [1, 0]
			else:
				weatherBits[1:3] = [1, 1]
		# SNOW
		if 'snow' in weatherCond['main']:
			# set weather bits to 1
			weatherBits[3] = 1
			if description == "light snow" or description == "light rain and snow" or description == "light shower snow":
				weatherBits[1:3] = [0, 1]
			elif description == "snow" or description == "rain and snow" or description == "shower snow":
				weatherBits[1:3] = [1, 0]
			else:
				weatherBits[1:3] = [1, 1]
		# LIGHTNING
		if 'thunderstorm' in weatherCond['main']:
			if description == "light thunderstorm" or description == "thunderstorm with light rain" or description == "thunderstorm with light drizzle":
				weatherBits[1:3] = [0, 1]
			elif description == "thunderstorm with rain" or description == "thunderstorm" or description == "thunderstorm with drizzle":
				weatherBits[1:3] = [1, 0]
			else:
				weatherBits[1:3] = [1, 1]


	###########################
	# 		BRIGHTNESS 		  #
	###########################

	# Get the cloud percentage
	# 1 = no clouds (i think)
	cloudiness = weatherDictionary['clouds']['all']

	if cloudiness < 25:
		brightnessBits[2:-1] = [1, 1, 1, 1, 1]
	elif cloudiness < 50:
		brightnessBits[2:-1] = [1, 1, 0, 0 ,0]
	elif cloudiness < 75:
		brightnessBits[2:-1] = [1, 0, 0, 0, 0]
	else:
		brightnessBits[2:-1] = [0, 1, 0, 0, 0]

	

	finalArray = brightnessBits + weatherBits

	print(finalArray)

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




