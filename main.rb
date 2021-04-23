require 'discordrb'
require 'active_support/all'
require 'httparty'
require 'json'
require 'base64'
require 'securerandom'
require 'pp'


module Helpers
  extend ActiveSupport::NumberHelper
end

BOT = Discordrb::Commands::CommandBot.new(token: ENV["DISCORD_TOKEN"], client_id: ENV["DISCORD_CLIENT_ID"], prefix: ENV["DISCORD_PREFIX"])

CLEARREACTION = "\u{1F44D}"

def awaitClear(message)
  message.react(CLEARREACTION)

  BOT.add_await!(Discordrb::Events::ReactionAddEvent, message: message, emoji: CLEARREACTION) do |_reaction_event|
    message.delete
  end
end

def help(event)
  message = event.channel.send_embed do |embed|
    embed.title = "Market Details"
    embed.colour = 0xa5af0d
    embed.description = "The $info and $c command will retrive up-today information from any coin being tracked by CoinGecko and Binance.us"

    embed.add_field(name: "$info command", value: "`$info coin-name` \n\nexample: \n`$info bitcoin`")

    embed.add_field(name: "$c command", value: "`$c ticker` \n\nexample: \n`$c dogeusd`")
  end

  awaitClear(message)
end

BOT.command :info do |event, coin|

  if coin == "help" || coin.nil? || coin.empty?
    help(event)
  else
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

      message = event.channel.send_embed do |embed|
        embed.title = "#{coinName} (#{coinSymbol.upcase})"
        embed.colour = 0x29e027
        embed.url = coinHomepage
      
        embed.thumbnail = Discordrb::Webhooks::EmbedThumbnail.new(url: coinImage)
        
        embed.add_field(name: "Details", value: "Market Cap: #{Helpers.number_to_currency(coinMaketCap)}\nTrading Volume: #{Helpers.number_to_currency(coinVolume)}\nCirculating Supply: #{Helpers.number_to_delimited(coinSupply)} #{coinSymbol.upcase}")
        embed.add_field(name: "Price", value: "Current: #{Helpers.number_to_currency(coinPrice)}\n24H High: #{Helpers.number_to_currency(coin24High)}\n24H Low: #{Helpers.number_to_currency(coin24Low)}", inline: true)
        embed.add_field(name: "Price Change", value: "Past 24H: #{Helpers.number_to_delimited(coinPastDay)} %\nPast Week: #{Helpers.number_to_delimited(coinPastWeek)} %\nPast Month: #{Helpers.number_to_delimited(coinPastMonth)} %\nPast Year: #{coinPastYear}%", inline: true)

        embed.add_field(name: "---", value: "[Data by Dabois.Capital](https://dabois.capital)")
      end

      awaitClear(message)
    else
      errorData = JSON.parse(requestCoin.body)

      message = event.channel.send_embed do |embed|
        embed.title = "We had an issue pulling #{coin}"
        embed.colour = 0xd0021b
        embed.description = "error code: #{requestCoin.code} ```\n#{errorData}```"
      end

      awaitClear(message)
    end
  end
end

BOT.command :c do |event, ticker|
  if ticker == "help" || ticker.nil? || ticker.empty?
    help(event)
  else
    ticker = ticker.upcase

    requestChart = HTTParty.get("http://chart-image.api.dabois.capital/#{ticker}/1h")

    if requestChart.code == 200
      chartData = JSON.parse(requestChart.body)

      img_from_base64 = Base64.decode64(chartData["img"].gsub("data:image/png;base64,", ""))

      imgPath = "charts/#{SecureRandom.uuid}.png"

      File.open(imgPath, 'wb') do|f|
        f.write(img_from_base64)
      end

      message = event.send_file(File.open(imgPath, 'r'))

      File.delete(imgPath) if File.exist?(imgPath)

      awaitClear(message)
    else
      errorData = JSON.parse(requestChart.body)

      message = event.channel.send_embed do |embed|
        embed.title = "We had an issue pulling #{ticker}"
        embed.colour = 0xd0021b
        embed.description = "error code: #{requestChart.code} ```\n#{errorData}```"
      end

      awaitClear(message)
    end
  end
end

BOT.run