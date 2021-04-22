require 'discordrb'
require 'active_support/all'
require 'httparty'
require 'json'
require 'pp'


module Helpers
  extend ActiveSupport::NumberHelper
end

bot = Discordrb::Commands::CommandBot.new(token: ENV["DISCORD_TOKEN"] || "xx", client_id: ENV["DISCORD_CLIENT_ID"] || "xx", prefix: ENV["DISCORD_PREFIX"] || "$")

bot.command :info do |event, coin|

  coin = coin.downcase

  requestCoin = HTTParty.get("https://api.coingecko.com/api/v3/coins/#{coin}?localization=false&tickers=false&market_data=true&community_data=false&developer_data=false&sparkline=false")

  if requestCoin.code == 200
    coinData = JSON.parse(requestCoin.body)

    coinName = coinData["name"]
    coinSymbol = coinData["symbol"]
    coinHomepage = coinData["links"]["homepage"][0]
    coinImage = coinData["image"]["large"]

    coinMaketCap = coinData["market_data"]["market_cap"]["usd"]
    coinVolume = coinData["market_data"]["total_volume"]["usd"]
    coinSupply = coinData["market_data"]["circulating_supply"]

    coinPrice = coinData["market_data"]["current_price"]["usd"]
    coin24High = coinData["market_data"]["high_24h"]["usd"]
    coin24Low = coinData["market_data"]["low_24h"]["usd"]

    coinPastDay = coinData["market_data"]["price_change_percentage_24h"]
    coinPastWeek = coinData["market_data"]["price_change_percentage_7d"]
    coinPastMonth = coinData["market_data"]["price_change_percentage_30d"]
    coinPastYear = coinData["market_data"]["price_change_percentage_1y"]

    event.channel.send_embed do |embed|
      embed.title = "#{coinName} (#{coinSymbol.upcase})"
      embed.colour = 0x29e027
      embed.url = coinHomepage
    
      embed.thumbnail = Discordrb::Webhooks::EmbedThumbnail.new(url: coinImage)
      
      embed.add_field(name: "Details", value: "Market Cap: #{Helpers.number_to_currency(coinMaketCap)}\nTrading Volume: #{Helpers.number_to_currency(coinVolume)}\nCirculating Supply: #{Helpers.number_to_delimited(coinSupply)} #{coinSymbol.upcase}")
      embed.add_field(name: "Price", value: "Current: #{Helpers.number_to_currency(coinPrice)}\n24H High: #{Helpers.number_to_currency(coin24High)}\n24H Low: #{Helpers.number_to_currency(coin24Low)}", inline: true)
      embed.add_field(name: "Price Change", value: "Past 24H: #{Helpers.number_to_delimited(coinPastDay)} %\nPast Week: #{Helpers.number_to_delimited(coinPastWeek)} %\nPast Month: #{Helpers.number_to_delimited(coinPastMonth)} %\nPast Year: #{coinPastYear}%", inline: true)

      embed.add_field(name: "---", value: "[Data by Dabois.Capital](https://dabois.capital)")
    end
  else
    errorData = JSON.parse(requestCoin.body)

    event.channel.send_embed do |embed|
      embed.title = "We had an issue pulling #{coin}"
      embed.colour = 0xd0021b
      embed.description = "error code: #{requestCoin.code} ```\n#{errorData}```"
    end
  end

end

bot.run