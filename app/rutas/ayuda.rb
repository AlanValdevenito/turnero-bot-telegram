require_relative '../constantes/mensajes'

class AyudaRoutes
  def self.register(routing)
    routing.default do |bot, message|
      help_text = MENSAJE_AYUDA
      bot.api.send_message(chat_id: message.chat.id, text: help_text)
    end
  end
end
