class VersionRoutes
  def self.register(routing)
    routing.on_message '/version' do |bot, message|
      response_version = Faraday.new("#{ENV['API_URL']}/version").get
      api_version = JSON.parse(response_version.body)['version']
      response = "Bot version: #{Version.current} - Api Version: #{api_version}"
      bot.api.send_message(chat_id: message.chat.id, text: response)
    end
  end
end
