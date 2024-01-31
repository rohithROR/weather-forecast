class HomeController < ApplicationController
	def index
		@temperature = ForecastService.new(params[:address]).get_forecast if params[:address].present?
	end
end
