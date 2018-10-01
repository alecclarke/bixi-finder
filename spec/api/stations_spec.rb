require 'rails_helper'

RSpec.describe "stations", :type => :request do
  after do
    # This behaviour should be moved into the spec_helper.
    Station.delete_all
  end

  before do
    Station.create!(availability: 1, lat: 0, lng: 0, station_id: 1, name: "Station1")
  end

  it "returns a JSON representation of the stations" do
    get "/api/stations", params: { lat: 1, lng: 1 }
    json_response = JSON.parse(response.body)

    expect(json_response).to eq(
      [
        {
          "availability"=>1,
          "lat"=>"0.0",
          "lng"=>"0.0",
          "name"=>"Station1",
          "station_id"=>1
        }
      ]
    )
  end
end