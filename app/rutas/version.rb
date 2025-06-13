class VersionRoutes
  def self.register(routing)
    routing.on_message '/version' do |bot, message|
      bot.logger.debug 'GET /version'
      turnero = Turnero.new(ProveedorTurnero.new(ENV['API_URL']))
      api_version = turnero.version
      version = "BOT version: #{Version.current} - API version: #{api_version}"
      bot.api.send_message(chat_id: message.chat.id, text: version)
    end
  end
end
