require "discordrb"
require_relative "api"

include API

if not ENV["CLASSIC_PARSER_TOK"] or not ENV["CLASSIC_PARSER_KEY"]
  puts "Err: Missing environment variable(s)"
  exit 1
end

bot = Discordrb::Commands::CommandBot.new token: ENV["CLASSIC_PARSER_TOK"], prefix: "?"

bot.command :logs do |event, *args|
  if args.length < 3
    "Usage: `?logs <character_name> <realm> <[US,NA], EU, KR, TW, CN>`"
  else
    charname = args[0].downcase
    realm = args[1].downcase
    region = args[2].downcase
    region = region.upcase == "NA" ? "US" : region
    parses = get_parses(charname, realm, region)

    top_parses = {}
    bosses = parses.map {|p| p["encounterName"]}.uniq
    bosses.each do |boss|
      filtered_parses = parses.select {|p| p["encounterName"] == boss}
      top_parse = filtered_parses.max {|a,b| a["percentile"] - b["percentile"]}
      top_parses[boss] = top_parse
    end
    avg_score = top_parses.values.inject(0){|sum,p| sum + p["percentile"].to_i}.to_f / bosses.length

    if top_parses.values.length < 1
      event.channel.send("Unable to find player `#{charname.capitalize}` on `#{realm.capitalize} #{region.upcase}`")
    else
      char_class = top_parses.values[0]["class"]
      embed_r = 1 - avg_score / 100
      embed_g = avg_score / 100
      embed_b = 0

      event.channel.send_embed() do |embed|
        embed.title = "Parse report for #{charname.capitalize} (#{realm.capitalize} #{region.upcase})"
        embed.description = "Overall score: #{"%.2f" % avg_score}"
        embed.colour = embed_r * 0xFF0000 + embed_g * 0x00FF00 + embed_b * 0x0000FF
        embed.url = "https://classic.warcraftlogs.com/character/#{region}/#{realm}/#{charname}"
        embed.thumbnail = Discordrb::Webhooks::EmbedThumbnail.new(url: "https://img.rankedboost.com/wp-content/uploads/2019/05/WoW-Classic-#{char_class}-Guide.png")
        embed.footer = Discordrb::Webhooks::EmbedFooter.new(text: "https://discord.gg/mRUEPnp", icon_url: "https://discordapp.com/assets/28174a34e77bb5e5310ced9f95cb480b.png")
        top_parses.each {|b, p|
          pct_str = p["percentile"] >= 95 ? "**#{p["percentile"]}**" : p["percentile"]; 
          report_url = "https://classic.warcraftlogs.com/reports/#{p["reportID"]}/\#fight=#{p["fightID"]}"
          embed.add_field(name: b, value: "#{pct_str} [Full report](#{report_url})")
        }
      end
    end
  end
end

bot.run
