require_relative '../constantes/mensajes'
require_relative '../turnero/excepciones/index'
require_relative '../turnero/turnero'
require_relative '../turnero/proveedor_turnero/proveedor_turnero'
require_relative 'errores_turno'
require_relative 'teclado_deshabilitado'

DESHABILITAR = 'disabled'.freeze

class PedirTurnoRoutes
  def self.register(routing)
    pedir_turno_on_message(routing)
    seleccionar_medico_on_response(routing)
    seleccionar_turno_on_response(routing)
  end

  def self.pedir_turno_on_message(routing)
    routing.on_message '/pedir-turno' do |bot, message|
      ErroresTurno.handle_error_pedir_turno(bot, message.chat.id) do
        markup = pedir_turno(message.from.id)
        bot.api.send_message(chat_id: message.chat.id, text: MENSAJE_SELECCIONE_MEDICO, reply_markup: markup)
      end
    end
  end

  def self.seleccionar_medico_on_response(routing)
    routing.on_response_to MENSAJE_SELECCIONE_MEDICO do |bot, message|
      if message.data == DESHABILITAR
        responder_medico_deshabilitado(bot, message)
        next
      end

      ErroresTurno.handle_error_seleccionar_medico(bot, message.message.chat.id) do
        procesar_seleccion_medico(bot, message)
      end
    end
  end

  def self.responder_medico_deshabilitado(bot, message)
    bot.api.answer_callback_query(callback_query_id: message.id, text: MENSAJE_MEDICO_YA_SELECCIONADO)
  rescue StandardError
    bot.api.send_message(chat_id: message.message.chat.id, text: MENSAJE_ERROR_GENERAL)
  end

  def self.procesar_seleccion_medico(bot, message)
    matricula, especialidad, email = message.data.split('|')
    TecladoDeshabilitado.disable_keyboard_buttons(bot, message, message.data)
    responder_callback_medico(bot, message)
    markup = turnos_disponibles(matricula, especialidad, email)
    bot.api.send_message(chat_id: message.message.chat.id, text: MENSAJE_SELECCIONE_TURNO, reply_markup: markup)
  end

  def self.responder_callback_medico(bot, message)
    bot.api.answer_callback_query(callback_query_id: message.id)
  rescue StandardError
    bot.api.send_message(chat_id: message.message.chat.id, text: MENSAJE_ERROR_GENERAL)
  end

  def self.seleccionar_turno_on_response(routing)
    routing.on_response_to MENSAJE_SELECCIONE_TURNO do |bot, message|
      ErroresTurno.handle_error_seleccionar_turno(bot, message.message.chat.id) do
        fecha, hora, matricula, _especialidad, email = message.data.split('|')

        response = reservar_turno(matricula, fecha, hora, email)
        bot.api.send_message(chat_id: message.message.chat.id, text: response)
      end
    end
  end

  def self.pedir_turno(telegram_id)
    turnero = Turnero.new(ProveedorTurnero.new(ENV['API_URL']))
    email = turnero.usuario_registrado?(telegram_id)
    medicos = turnero.solicitar_medicos_disponibles
    kb = medicos.map do |m|
      callback_data = "#{m.matricula}|#{m.especialidad}|#{email}"
      [Telegram::Bot::Types::InlineKeyboardButton.new(text: "#{m.nombre} #{m.apellido}", callback_data:)]
    end
    Telegram::Bot::Types::InlineKeyboardMarkup.new(inline_keyboard: kb)
  end

  def self.turnos_disponibles(matricula, especialidad, email)
    turnero = Turnero.new(ProveedorTurnero.new(ENV['API_URL']))
    turnos = turnero.solicitar_turnos_disponibles(matricula, especialidad)
    kb = turnos.map do |t|
      callback_data = "#{t.fecha}|#{t.hora}|#{matricula}|#{especialidad}|#{email}"
      [Telegram::Bot::Types::InlineKeyboardButton.new(text: "#{t.fecha} - #{t.hora}", callback_data:)]
    end
    Telegram::Bot::Types::InlineKeyboardMarkup.new(inline_keyboard: kb)
  end

  def self.reservar_turno(matricula, fecha, hora, email)
    turnero = Turnero.new(ProveedorTurnero.new(ENV['API_URL']))
    turno = turnero.reservar_turno(matricula, fecha, hora, email)
    format(MENSAJE_TURNO_CONFIRMADO, fecha: turno.fecha, hora: turno.hora, medico: "#{turno.medico.nombre} #{turno.medico.apellido}", especialidad: turno.medico.especialidad)
  end
end
