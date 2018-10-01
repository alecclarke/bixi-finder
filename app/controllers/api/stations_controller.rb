class Api::StationsController < ApplicationController
  def show
    FindClosestAvailableStations.new(
      ip: params[:ip],
      lat: params[:lat],
      lng: params[:lng],
    ).call    
  end
end
