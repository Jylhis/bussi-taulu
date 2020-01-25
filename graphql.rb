require 'faraday'
require 'json'
require 'date'
require 'colorize'

# Helsinki_region = https://api.digitransit.fi/routing/v1/routers/hsl/index/graphql
Waltti_region = "https://api.digitransit.fi/routing/v1/routers/waltti/index/graphql"
# Entire_finland = https://api.digitransit.fi/routing/v1/routers/finland/index/graphql

Satamatie_P = "OULU:120657"
Lämpövoimala_E = "OULU:121505"

query_string = 'query {
  stops(ids: ["OULU:120657","OULU:121505"]) {
    gtfsId
    name
    stoptimesWithoutPatterns(timeRange: 10800, omitNonPickups: true) {
      scheduledDeparture
      realtimeDeparture
      realtime
      trip {
        pattern {
          route {
            shortName
            longName
          }
        }
      }
    }
   }
}'

if !File.file? "cache.json"
    result= Faraday.post(Waltti_region, query_string, "Content-Type" => "application/graphql")

    if result.status != 200
        puts result.status
        puts result.body
        abort("query FAILED")
    end
    File.write('cache.json', result.body)
end


parsed = JSON.parse(File.read("cache.json"))

today = Time.now
today_midnight_timestamp = Time.local(today.year, today.month, today.day, 0, 0, 0).to_i

for stop in parsed['data']['stops']
    puts stop['name']
    for departure in stop['stoptimesWithoutPatterns']
        departure_time = ""
        busname = departure['trip']['pattern']['route']['shortName']
        route = departure['trip']['pattern']['route']['longName']

        if departure['realtime']
            departure_time = Time.at today_midnight_timestamp + departure['realtimeDeparture']
            departure_time = departure_time.to_s.green
        else
            departure_time = Time.at today_midnight_timestamp + departure['scheduledDeparture']
        end
        
        printf "%-7s %-30s %s\n", busname, route, departure_time
    end        
end