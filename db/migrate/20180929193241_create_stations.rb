class CreateStations < ActiveRecord::Migration[5.2]
  def change
    create_table :stations do |t|
      # Since bixi has it's own ids for these stations, we should store their reference to the bixi database so we have reference to them for finding the avaliablity.
      t.integer :station_id, null: false
      # scale 5 gives us precision within 1.1132m which should be enough for finding the closest location.
      # scale 6 would be 111.32mm (probably overkill for this application).
      t.decimal :lat, precision: 8, scale: 5, null: false
      t.decimal :lng, precision: 8, scale: 5, null: false
      # The default size is 255 which may be too much considering the names of the station locations in bixi, 
      # however this gives us some flexibilty going forward if we encounter a location name the is abnormally long.
      t.string :name, null: false
      # limit: 1 would have a limit of 127 - by adding one more byte, we have a limit of 32,767 which should be ample.
      t.integer :availability, limit: 2, null: false, default: 0
      t.timestamps
    end

    # adding an index to improve the geo-kit performance for calculating the distances between stations and the given point.
    add_index :stations, [:lat, :lng]
    # Index stations on the station_id as we will us the reference to update the station avalability in our db.
    # Also, we want this to be a unique index as there shouldn't be duplicate references to bixi stations.
    add_index :stations, :station_id, unique: true
  end
end
