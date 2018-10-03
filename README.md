# README

## Building and running the project
1. Make sure [Docker](https://www.docker.com/get-started) is installed.
2. Run:
```
docker-compose build
```
3. Run:
```
docker-compose run web yarn install
```
4. Run:
```
docker-compose run web bundle exec rake db:create db:migrate db:seed
```
5. Run:
```
docker-compose up
```
6. Navigate to `localhost:3000` in your browser.

7. Tests can be run via:
```
docker-compose run web bundle exec rspec spec

```

## Design considerations
### Assumptions/General notes
Since the availability (also the existence of station, though this should change less frequently) of the bikes at each BIXI station is information that is stored on in the BIXI database, we would need to keep our database in sync with theirs. In this approach, this functionality isn't included, we simply load the current state of the BIXI stations into the database via `rake db:seed`.

If I were to iterate on this application, keeping these databases in sync we be my first priority. If the BIXI API was equipped with webhooks, or push notifications to update the availability of bikes at stations, this could make the process more feasible.

Also, as an alternative, seeing as how the number of stations is ~500, we could make this app without a database and just build from the BIXI API endpoints as processing the distances between the given origin and the returned stations would be relatively quick in memory (this approach doesn't scale at all).

### Schema
The schema for this application has been left rather simple. There is one table which represents the stations location and their availability. This decision to leave to the schema as one table came from the fact that we simply only need to determine a stations distance (from the origin given) and if it has an available bike to use. At this time, those requirements don't give me a reason to split the schema into further tables. Also, the location, and availability (# of bikes) of the the bikes at the station make sense to me to be on the same table as they are used together for our only queries.

However, if we were to obtain more knowledge of the BIXI domain, say the bikes themselves, we could associate bikes (when in a vacant state) to the stations they currently reside. In this case we would calculate the availability of a station through a join (bikes indexed on current_station_id) to the bikes table.

In this approach, calculating the distance between the given origin and the BIXI stations was done through a relatively naive method. Given the origin point, we calculate the distance (using spherical distance calculated by Haversine calculations - via the geokit-rails gem) between it and all the stations, then sort on the availability, then provide a limit to the results returned. Unfortunately this approach results in a table scan every time (at the scale of ~500 stations this is actually quite fast, but again, it doesn't scale).

```
bixi_finder_development=# EXPLAIN (FORMAT JSON) SELECT "stations".* FROM "stations" WHERE (stations.lat IS NOT NULL AND stations.lng IS NOT NULL) AND (stations.availability > 0) ORDER BY 
(ACOS(least(1,COS(0.7942359871307719)*COS(-1.2832460021459724)*COS(RADIANS(stations.lat))*COS(RADIANS(stations.lng))+
COS(0.7942359871307719)*SIN(-1.2832460021459724)*COS(RADIANS(stations.lat))*SIN(RADIANS(stations.lng)) + SIN(0.7942359871307719)*SIN(RADIANS(stations.lat))))*3963.1899999999996) ASC LIMIT 3;
                                                                                                                                             
                                                                     QUERY PLAN                                                              
                                                                                                                                             
        
---------------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------------
--------
 [                                                                                                                                                                                                                                                                                      +
   {                                                                                                                                                                                                                      +
     "Plan": {                                                                                                                               
       +
       "Node Type": "Limit",                     
       +
       "Parallel Aware": false,                                                                                                              
       +
       "Startup Cost": 53.13,                                                                                                               
       +
       "Total Cost": 53.14,                                                                                                                
       +
       "Plan Rows": 3,                                                                                                                    
       +
       "Plan Width": 79,                                                                                                                    
       +
       "Plans": [                                                                                                                           
       +
         {                                                                                                                                  
       +
           "Node Type": "Sort",                                                                                                              
       +
           "Parent Relationship": "Outer",                                                                                                   
       +
           "Parallel Aware": false,                                                                                                         
       +
           "Startup Cost": 53.13,                                                                                                           
       +
           "Total Cost": 54.40,                                                                                                            
       +
           "Plan Rows": 507,                                                                                                               
       +
           "Plan Width": 79,                                                                                                               
       +
           "Sort Key": ["((acos(LEAST('1'::double precision, (((('0.198758168839934'::double precision * cos(radians((lat)::double precision)
)) * cos(radians((lng)::double precision))) + (('-0.672054928392691'::double precision * cos(radians((lat)::double precision))) * sin(radians
((lng)::double precision)))) + ('0.713328370067034'::double precision * sin(radians((lat)::double precision)))))) * '3963.19'::double precisi
on))"],+
           "Plans": [                                                                                                                       
       +
             {                                                                                                                             
       +
               "Node Type": "Seq Scan",                               
       +
               "Parent Relationship": "Outer",                                                                                              
       +
               "Parallel Aware": false,                                                                                                    
       +
               "Relation Name": "stations",                                                                                                  
       +
               "Alias": "stations",                                                                                                        
       +
               "Startup Cost": 0.00,                                                                                                        
       +
               "Total Cost": 46.58,                                                                                                         
       +
               "Plan Rows": 507,                                                                                                           
       +
               "Plan Width": 79,                                                                                                             
       +
               "Filter": "((lat IS NOT NULL) AND (lng IS NOT NULL) AND (availability > 0))"                                                 
       +
             }                                                                                                                             
       +
           ]                                                                                                                                
       +
         }                                                  
       +
       ]                                                
       +
     }                                            
       +
   }                                                                                                                                                                                                                 
       +
 ]
(1 row)
```

While this approach isn't particularly scalable, I did find two other methods that would allow for easy indexing of the distances of stations (making the performance of calculating distances fast at scale). PostgreSQL is provided with an [extenstion](https://www.postgresql.org/docs/8.3/static/earthdistance.html) that allows us to calculate a location point on the earth's surface given an origin point (latitude + longitude). This point can then be indexed. So as we created stations in our database, we could calculate this earth point in the process, and store + index this value on the stations table, that way it would be much faster to compare distances between stations an origin point (we would also calculate the earth point for the given origin).

Related to this method, there exists a PostgreSQL extender called [PostGIS](https://postgis.net/) which again, allows us to more efficiently calculate distances between station records and given points.

I didn't use either of these methods as it didn't seem like vanilla PostgreSQL to me (one of the requirements of the assessment). I also had trouble getting these extensions to work in my Docker setup (maybe I will add an image later to make this easier in the future).

### Interface

I tried to make the interface for this application very simple. The controller accepts locations parameters (lat, lng, ip) and a limit (how many stations are returned). This controller then delegates the actual work of querying for the records to a service object whose responsibility is solely to find the closest non-vacant stations.

By separating the the knowledge of active record, and the database for that matter, from the controller - we're setting up a single point of access to the station records from the application (something you wouldn't want to define at the controller level as that doesn't provide an interface to other internal components down the road). By doing this, we have a clean interface for accessing stations which allows the behaviour of fetching stations to be uniform across the application, as we always access them the same way. This also makes testing, maintenance, and readability/understanding much better as we aren't redefining and testing this behaviour all over the app, leading to bugs, hard to maintain bugs with these queries, and hard to understand code.

Note: Originally searching by the users location (through their IP) was included in the application functionality, however there are issues with `geokit-rails` accepting canadian IP addresses (something I would have to dig into more). 

### UI

Admittedley, the UI for this assessment was put together quickly to provide a simple interface, but it does provide the skeleton to build from. I used the baked-in rails webpacker + react approach which made it simple to get a react component working in Rails, and would make it easy to create a SPA from the application (I didn't add ui-routing to the project as it truly was single page app).

With more time to iterate on the design I would add the following:
1. Tests for the react component (I ran into an issue when trying to get Jest running in the Application).
2. better code organizations and abstractions.
2. Improved styling.
3. Displaying the closest locations on a google maps component.

... to name a few.
