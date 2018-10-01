class Api::StationsController < ApplicationController
  def index
    @stations = FindClosestAvailableStations.new(
      ip: params[:ip], # TODO: Fix config in GeoKit to make this work for Canadian IPs.
      lat: params[:lat],
      lng: params[:lng],
      limit: params[:limit],
    ).call    
  end
end
