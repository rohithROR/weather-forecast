require 'rails_helper'

RSpec.describe ForecastService, type: :model do
  context 'when the address is valid' do
    let(:address) { 'Valid Address, City' }
    let(:forecast_service) { ForecastService.new(address) }

    it 'returns forecast data' do
      # Mock the Geocoder response
      allow(Geocoder).to receive(:search).with(address).and_return([double('GeocoderResult', latitude: 123, longitude: 456, city: 'City', address: address)])

      # Mock the Rails.cache methods
      allow(Rails.cache).to receive(:read).and_return(nil)
      allow(Rails.cache).to receive(:write)

      # Mock the Weather API request
      allow(forecast_service).to receive(:get_weather_data).with('City').and_return(valid_weather_data)

      # Call the service method
      forecast_data = forecast_service.get_forecast

      # Make assertions
      expect(forecast_data).to include(
        current: hash_including(last_updated: DateTime, temp_c: Numeric, feelslike_c: Numeric, temp_f: Numeric, feelslike_f: Numeric, condition: String),
        forecast: hash_including(maxtemp_c: Numeric, maxtemp_f: Numeric, mintemp_c: Numeric, mintemp_f: Numeric, avgtemp_c: Numeric, avgtemp_f: Numeric, condition: String)
      )
      expect(Rails.cache).to have_received(:read).once
      expect(Rails.cache).to have_received(:write).once
    end

    # Add more tests for different scenarios, e.g., when the data is in the cache, when the Weather API request fails, etc.
  end

  context 'when the address is invalid' do
    let(:address) { 'Invalid Address' }
    let(:forecast_service) { ForecastService.new(address) }

    it 'returns nil' do
      # Mock the Geocoder response for an invalid address
      allow(Geocoder).to receive(:search).with(address).and_return([])

      # Call the service method
      forecast_data = forecast_service.get_forecast

      # Make assertions
      expect(forecast_data).to be_nil
    end
  end

  describe '#get_weather_data' do
    it 'returns weather data from the Weather API' do
      # Mock the Geocoder response to set up @address
      allow(Geocoder).to receive(:search).and_return([double('GeocoderResult', latitude: 123, longitude: 456, city: 'City', address: 'Valid Address, City')])

      # Create a ForecastService instance with an address
      forecast_service = ForecastService.new('Valid Address, City')

      # Mock the Weather API request with a valid response
      allow(forecast_service).to receive(:get_weather_data).and_return(valid_weather_data)

      # Call the private method
      weather_data = forecast_service.send(:get_weather_data, 'City')

      # Make assertions
      expect(weather_data).to eq(valid_weather_data)
    end

    it 'returns nil for invalid API response' do
      # Mock the Geocoder response to set up @address
      allow(Geocoder).to receive(:search).and_return([])

      # Create a ForecastService instance with an address
      forecast_service = ForecastService.new('Invalid Address')

      # Mock the Weather API request with an invalid response
      allow(forecast_service).to receive(:get_weather_data).and_return(nil)

      # Call the private method
      weather_data = forecast_service.send(:get_weather_data, 'City')

      # Make assertions
      expect(weather_data).to be_nil
    end
  end

  describe '#parse_weather_data' do
    it 'parses valid weather data from the API response' do
      # Create a ForecastService instance (initialize and get_weather_data are already tested)
      forecast_service = ForecastService.new('Valid Address, City')
      allow(forecast_service).to receive(:get_weather_data).and_return(valid_weather_data)

      # Call the private method
      parsed_data = forecast_service.send(:parse_weather_data, valid_weather_data)
      # Make assertions
      expect(parsed_data).to eq(valid_parse_weather_data)
    end

    it 'returns nil for invalid weather data' do
      # Sample invalid weather data (missing required fields)
      invalid_weather_data = {}

      # Create a ForecastService instance (initialize and get_weather_data are already tested)
      forecast_service = ForecastService.new('Valid Address, City')
      allow(forecast_service).to receive(:get_weather_data).and_return(invalid_weather_data)

      # Call the private method
      parsed_data = forecast_service.send(:parse_weather_data, invalid_weather_data)

      # Make assertions
      expect(parsed_data).to be_nil
    end
  end

  def valid_weather_data
    {
      'current' => {
        'last_updated' => '2024-02-01T12:00:00',
        'temp_c' => 25,
        'feelslike_c' => 27,
        'temp_f' => 77,
        'feelslike_f' => 80,
        'condition' => 'Sunny'
      },
      'forecast' => {
        'forecastday' => [
          'day' => {
            'maxtemp_c' => 30,
            'maxtemp_f' => 86,
            'mintemp_c' => 20,
            'mintemp_f' => 68,
            'avgtemp_c' => 25,
            'avgtemp_f' => 77,
            'condition' => 'Partly Cloudy'
          }
        ]
      }
    }
  end

  def valid_parse_weather_data
    {
      current: {
        last_updated: DateTime.parse('2024-02-01 12:00'),
        temp_c: 25,
        feelslike_c: 27,
        temp_f: 77,
        feelslike_f: 80,
        condition: 'Sunny'
      },
      forecast: {
        maxtemp_c: 30,
        maxtemp_f: 86,
        mintemp_c: 20,
        mintemp_f: 68,
        avgtemp_c: 25,
        avgtemp_f: 77,
        condition: 'Partly Cloudy'
      }
    }
  end
end
