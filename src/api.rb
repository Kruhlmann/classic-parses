require "rest-client"
require "json"

$base_url = "https://classic.warcraftlogs.com:443/v1"
$key = ENV["CLASSIC_PARSER_KEY"]

module API
  def get_parses(char, server, region)
    res = RestClient.get("#{$base_url}/parses/character/#{char}/#{server}/#{region}?api_key=#{$key}")
    JSON.parse(res.body)
  end
end
