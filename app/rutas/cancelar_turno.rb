require_relative '../constantes/mensajes'
require_relative '../turnero/turnero'
require_relative '../turnero/proveedor_turnero/proveedor_turnero'

class CancelarTurnoRoutes
  def self.register(routing)
    cancelar_turno_on_message(routing)
    seleccionar_confirmacion_on_response(routing)
  end

  def self.cancelar_turno_on_message(routing)
    routing.on_message_pattern %r{/cancelar-turno (?<id>.*)} do |bot, message, args|
      bot.logger.debug("/cancelar-turno: #{args}")
      begin
        turnero = Turnero.new(ProveedorTurnero.new(ENV['API_URL'], ENV['API_KEY']))
        email = turnero.usuario_registrado?(message.from.id)
        procesar_cancelar_turno(bot, message, args['id'], email, turnero)
      rescue UsuarioNoRegistradoException
        bot.api.send_message(chat_id: message.from.id, text: MENSAJE_NO_REGISTRADO)
      end
    end
  end

  def self.procesar_cancelar_turno(bot, message, id, email, turnero)
    handle_error_cancelacion(bot, message.chat.id, id, email) do
      turnero.cancelar_turno(id, email, false)
      bot.api.send_message(chat_id: message.chat.id, text: MENSAJE_TURNO_CANCELADO)
    end
  end

  def self.handle_error_cancelacion(bot, chat_id, turno_id, email)
    yield
  rescue CancelacionNecesitaConfirmacionException
    kb = [[Telegram::Bot::Types::InlineKeyboardButton.new(text: 'Si', callback_data: "true|#{turno_id}|#{email}")],
          [Telegram::Bot::Types::InlineKeyboardButton.new(text: 'No', callback_data: "false|#{turno_id}|#{email}")]]

    markup = Telegram::Bot::Types::InlineKeyboardMarkup.new(inline_keyboard: kb)

    bot.api.send_message(chat_id:, text: MENSAJE_CONFIRMAR_CANCELACION_TURNO, reply_markup: markup)
  rescue NoPodesCancelarTurnoInexistenteException
    bot.api.send_message(chat_id:, text: MENSAJE_NO_PODES_CANCELAR_ESTE_TURNO)
  rescue StandardError => e
    puts "Error completo: #{e.message}"
    bot.api.send_message(chat_id:, text: MENSAJE_ERROR_GENERAL)
  end

  def self.seleccionar_confirmacion_on_response(routing)
    routing.on_response_to MENSAJE_CONFIRMAR_CANCELACION_TURNO do |bot, message|
      confirmacion, turno_id, email = message.data.split('|')
      if confirmacion == 'true'
        confirmar_cancelacion(turno_id, email, bot, message)
      else
        rechazar_cancelacion(bot, message)
      end
    end
  end

  def self.confirmar_cancelacion(turno_id, email, bot, message)
    turnero = Turnero.new(ProveedorTurnero.new(ENV['API_URL'], ENV['API_KEY']))
    turnero.cancelar_turno(turno_id, email, true)
    bot.api.send_message(chat_id: message.message.chat.id, text: MENSAJE_TURNO_AUSENTE)
  end

  def self.rechazar_cancelacion(bot, message)
    bot.api.send_message(chat_id: message.message.chat.id, text: MENSAJE_RECHAZAR_CANCELACION_TURNO)
  end
end
