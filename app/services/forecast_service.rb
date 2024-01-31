class ForecastService
	def initialize(address)
		@address = address
	end
	def get_forecast
    response = Geocoder.search(@address)
    return nil if response.blank?
    weather_data = get_weather_data(response.first.city)
    weather_data ? parse_weather_data(weather_data).merge({address: response.first.address}) : nil
  end

  private

  def get_weather_data(city)
    
    api_url = URI.parse("https://api.weatherapi.com/v1/forecast.json?key=7211b876e30b41a18e1174653243001&q=#{city}&days=1&aqi=no&alerts=no") rescue (return nil)
    http = Net::HTTP.new(api_url.host, api_url.port)
    http.use_ssl = (api_url.scheme == 'https')
    request = Net::HTTP::Get.new(api_url.request_uri)
    response = http.request(request)
    if response.code.to_i >= 200 && response.code.to_i < 300
    	JSON.parse(response.body)
    else
    	nil
    end
  end

  def parse_weather_data(weather_data)
  	current_data = weather_data['current']
  	forecast_data = weather_data['forecast']['forecastday'].first['day']
  	{
  		current:{
  			last_updated: DateTime.parse(current_data['last_updated']),
  			temp_c: current_data['temp_c'],
  			feelslike_c: current_data['feelslike_c'],
  			temp_f: current_data['temp_f'],
  			feelslike_f: current_data['feelslike_f'],
  			condition: current_data['condition'],
  		},
  		forecast:{
  			maxtemp_c: forecast_data['maxtemp_c'],
  			maxtemp_f: forecast_data['maxtemp_f'],
  			mintemp_c: forecast_data['mintemp_c'],
  			mintemp_f: forecast_data['mintemp_f'],
  			avgtemp_c: forecast_data['avgtemp_c'],
  			avgtemp_f: forecast_data['avgtemp_f'],
  			condition: forecast_data['condition'],
  		}
  	}
  end
end