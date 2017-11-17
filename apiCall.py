import requests
from tzwhere import tzwhere
from datetime import datetime
from pytz import timezone

API_KEY = '4f6f8f30f593ed64cec14b81dd480eb2'

def multiply(a,b):
    print("Will compute", a, "times", b)
    c = 0
    for i in range(0, a):
        c = c + b
    return c

    
def getWeather(zipCode):

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





