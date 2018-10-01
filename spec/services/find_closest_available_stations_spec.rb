require 'rails_helper'

RSpec.describe FindClosestAvailableStations do
  describe "#initialize" do
    context "when lat, lng, and ip are blank" do
      it "raises an error" do
        expect { described_class.new().to raise_error(FindClosestAvailableStations::MissingOriginError) }
      end
    end
  end

  describe "#call" do
    let!(:station1) { Station.create!(availability: 1, lat: 0, lng: 0, station_id: 1, name: "Station1") }
    let!(:station2) { Station.create!(availability: 2, lat: 10, lng: 10, station_id: 2, name: "Station2") }
    let!(:station3) { Station.create!(availability: 3, lat: 20, lng: 20, station_id: 3, name: "Station3") }
    let!(:station4) { Station.create!(availability: 4, lat: 30, lng: 30, station_id: 4, name: "Station4") }
    let!(:station5) { Station.create!(availability: 0, lat: 40, lng: 40, station_id: 5, name: "Station5") }

    after(:all) do
      # This behaviour should be moved into the spec_helper.
      Station.delete_all
    end

    context "when a limit is provided" do
      it "returns the 4 closest stations with an available bike" do
        stations = described_class.new(lat: 40, lng: 40, limit: 4).call
        expect(stations.length).to eq(4)
        expect(stations).to include(station1, station2, station3, station4)
      end
    end

    context "when a limit isn't provided" do
      it "returns the 3 closest stations with an available bike" do
        stations = described_class.new(lat: 40, lng: 40).call
        expect(stations.length).to eq(3)
        expect(stations).to include(station2, station3, station4)
      end
    end

    context "when a ip is provided" do
      it "returns the closest station to the geolocated ip origin" do
        stations = described_class.new(ip: "12.215.42.19", limit: 1).call
        expect(stations.length).to eq(1)
        expect(stations).to include(station1)
      end
    end

    context "when lat and lng are provided" do
      it "returns the closest station to the givin lat/lng origin" do
        stations = described_class.new(lat: 10, lng: 10, limit: 1).call
        expect(stations.length).to eq(1)
        expect(stations).to include(station2)      
      end
    end
  end
end