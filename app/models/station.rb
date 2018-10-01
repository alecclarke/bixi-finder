class Station < ApplicationRecord
  acts_as_mappable

  validates :name, :station_id, :lat, :lng, :availability, presence: true
end
