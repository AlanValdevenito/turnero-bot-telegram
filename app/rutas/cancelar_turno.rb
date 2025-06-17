require_relative '../constantes/mensajes'
require_relative '../turnero/turnero'
require_relative '../turnero/proveedor_turnero/proveedor_turnero'

class CancelarTurnoRoutes
  def self.register(routing)
    cancelar_turno_on_message(routing)
  end

  def self.cancelar_turno_on_message(routing)
    routing.on_message_pattern %r{/cancelar-turno (?<id>.*)} do |bot, message, args|
      procesar_cancelar_turno(bot, message, args['id'])
    end
  end

  def self.procesar_cancelar_turno(bot, message, id)
    turnero = Turnero.new(ProveedorTurnero.new(ENV['API_URL']))
    email = turnero.usuario_registrado?(message.from.id)
    handle_error_cancelacion(bot, message.chat.id, email) do
      turnero.cancelar_turno(id, email, false)
    end
    bot.api.send_message(chat_id: message.chat.id, text: MENSAJE_TURNO_CANCELADO)
  end

  def self.handle_error_cancelacion(bot, chat_id, email)
    yield
  rescue CancelacionNecesitaConfirmacionException
    kb = [[Telegram::Bot::Types::InlineKeyboardButton.new(text: 'Si', callback_data: "true|#{email}")],
          [Telegram::Bot::Types::InlineKeyboardButton.new(text: 'No', callback_data: "false|#{email}")]]

    markup = Telegram::Bot::Types::InlineKeyboardMarkup.new(inline_keyboard: kb)

    bot.api.send_message(chat_id: message.chat.id, text: MENSAJE_CONFIRMAR_CANCELACION_TURNO, reply_markup: markup)
  rescue StandardError => e
    puts "Error completo: #{e.message}"
    bot.api.send_message(chat_id:, text: MENSAJE_ERROR_GENERAL)
  end
end
