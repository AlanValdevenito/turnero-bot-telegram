require_relative '../constantes/mensajes'
require_relative '../turnero/excepciones/index'
require_relative '../turnero/turnero'
require_relative '../turnero/proveedor_turnero/proveedor_turnero'
require_relative 'errores_turno'
require_relative 'teclado_deshabilitado'
require_relative 'routing_helper'

DESHABILITAR = 'disabled'.freeze

class PedirTurnoRoutes
  def self.register(routing)
    pedir_turno_on_message(routing)
    seleccionar_tipo_reserva_on_response(routing)
    seleccionar_turno_on_response(routing)
  end

  def self.pedir_turno_on_message(routing)
    routing.on_message '/pedir-turno' do |bot, message|
      ErroresTurno.handle_error_pedir_turno(bot, message.chat.id) do
        bot.logger.debug('/pedir-turno')
        markup = pedir_turno(message.from.id)
        bot.api.send_message(chat_id: message.chat.id, text: MENSAJE_SELECCIONE_TIPO_RESERVA, reply_markup: markup)
      end
    end
  end

  def self.pedir_turno(telegram_id)
    turnero = Turnero.new(ProveedorTurnero.new(ENV['API_URL'], ENV['API_KEY']))
    turnero.usuario_registrado?(telegram_id)

    kb = [[Telegram::Bot::Types::InlineKeyboardButton.new(text: 'Por especialidad', callback_data: 'pedir_turno_especialidad')],
          [Telegram::Bot::Types::InlineKeyboardButton.new(text: 'Por medico', callback_data: 'pedir_turno_medico')]]

    Telegram::Bot::Types::InlineKeyboardMarkup.new(inline_keyboard: kb)
  end

  def self.seleccionar_tipo_reserva_on_response(routing)
    RoutingHelper.response_to(routing)
  end

  def self.seleccionar_turno_on_response(routing)
    routing.on_response_to MENSAJE_SELECCIONE_TURNO do |bot, message|
      if message.data == DESHABILITAR
        responder_turno_deshabilitado(bot, message)
        next
      end
      ErroresTurno.handle_error_seleccionar_turno(bot, message.message.chat.id) do
        procesar_seleccion_turno(bot, message)
      end
    end
  end

  def self.procesar_seleccion_turno(bot, message)
    TecladoDeshabilitado.disable_keyboard_buttons(bot, message, message.data)
    fecha, hora, matricula, _especialidad, email = message.data.split('|')
    response = reservar_turno(matricula, fecha, hora, email)
    bot.api.send_message(chat_id: message.message.chat.id, text: response)
  end

  def self.responder_turno_deshabilitado(bot, message)
    bot.api.answer_callback_query(callback_query_id: message.id, text: MENSAJE_TURNO_YA_SELECCIONADO)
  rescue StandardError
    bot.api.send_message(chat_id: message.message.chat.id, text: MENSAJE_ERROR_GENERAL)
  end

  def self.reservar_turno(matricula, fecha, hora, email)
    turnero = Turnero.new(ProveedorTurnero.new(ENV['API_URL'], ENV['API_KEY']))
    turno = turnero.reservar_turno(matricula, fecha, hora, email)
    format(MENSAJE_TURNO_CONFIRMADO, fecha: turno.fecha, hora: turno.hora, medico: "#{turno.medico.nombre} #{turno.medico.apellido}", especialidad: turno.medico.especialidad)
  end
end
