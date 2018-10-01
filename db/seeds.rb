Station.delete_all

# Populating the db with these requests could be moved to a seperate service if we intended to
# use this functionality more. This service would also need to consider how we plan to keep our db
# in sync with the bixi db.

# Create station records.
station_response = HTTParty.get("https://api-core.bixi.com/gbfs/en/station_information.json")
station_data = station_response["data"]["stations"]

station_data.each do |station|
  Station.create!(
    station_id: station["station_id"],
    lat: station["lat"].round(5),
    lng: station["lon"].round(5),
    name: station["name"],
  )
end

# Update station records with their availability,
availability_response = HTTParty.get("https://api-core.bixi.com/gbfs/en/station_status.json")
availability_data = availability_response["data"]["stations"]

availability_data.each do |availability|
  station = Station.find_by(station_id: availability["station_id"].to_i)
  station.update_columns(availability: availability["num_bikes_available"])
end
