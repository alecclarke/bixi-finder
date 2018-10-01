class FindClosestAvailableStations
  class MissingOriginError < StandardError; end
 
  def initialize(ip: nil, lat: nil, lng: nil, limit: 3)
    @ip = ip
    @lat = lat
    @lng = lng
    @limit = limit

    raise MissingOriginError if missing_origin?
  end

  def call
    Station.by_distance(origin: origin).where("stations.availability > 0").limit(limit)
  end

  private

  attr_reader :ip, :lat, :lng, :limit

  def origin
    raise MissingOriginError if ip.blank? && (lat.blank? || lng.blank?)

    ip || [lat, lng]
  end

  def missing_origin?
    ip.blank? && (lat.blank? || lng.blank?)
  end
end