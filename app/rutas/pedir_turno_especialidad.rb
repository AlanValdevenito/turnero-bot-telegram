require_relative '../constantes/mensajes'
require_relative '../turnero/excepciones/index'
require_relative '../turnero/turnero'
require_relative '../turnero/proveedor_turnero/proveedor_turnero'
require_relative 'errores_turno'
require_relative 'teclado_deshabilitado'
require_relative 'routing_helper'

DESHABILITAR = 'disabled'.freeze

class PedirTurnoEspecialidadRoutes
  def self.register(routing)
    seleccionar_especialidad_on_response(routing)
  end

  def self.pedir_turno(bot, message)
    ErroresTurno.handle_error_pedir_turno(bot, message.from.id) do
      turnero = Turnero.new(ProveedorTurnero.new(ENV['API_URL']))
      email = turnero.usuario_registrado?(message.from.id)
      especialidades = turnero.solicitar_especialidades_disponibles

      bot.api.send_message(chat_id: message.from.id, text: MENSAJE_SELECCIONE_ESPECIALIDAD, reply_markup: crear_markup(especialidades, email))
    end
  end

  def self.crear_markup(especialidades, email)
    kb = especialidades.map do |e|
      callback_data = "#{e.nombre}|#{email}"
      [Telegram::Bot::Types::InlineKeyboardButton.new(text: e.nombre.to_s, callback_data:)]
    end

    Telegram::Bot::Types::InlineKeyboardMarkup.new(inline_keyboard: kb)
  end

  def self.seleccionar_especialidad_on_response(routing)
    routing.on_response_to MENSAJE_SELECCIONE_ESPECIALIDAD do |bot, message|
      ErroresTurno.handle_error_seleccionar_especialidad(bot, message.message.chat.id) do
        procesar_seleccion_especialidad(bot, message)
      end
    end
  end

  def self.procesar_seleccion_especialidad(bot, message)
    especialidad, email = message.data.split('|')
    responder_callback_especialidad(bot, message)

    markup = medicos_por_especialidad_disponibles(especialidad, email)

    bot.api.send_message(chat_id: message.message.chat.id, text: MENSAJE_SELECCIONE_MEDICO, reply_markup: markup)
  end

  def self.responder_callback_especialidad(bot, message)
    bot.api.answer_callback_query(callback_query_id: message.id)
  rescue StandardError
    bot.api.send_message(chat_id: message.message.chat.id, text: MENSAJE_ERROR_GENERAL)
  end

  def self.medicos_por_especialidad_disponibles(especialidad, email)
    turnero = Turnero.new(ProveedorTurnero.new(ENV['API_URL']))
    medicos = turnero.solicitar_medicos_por_especialidad_disponibles(especialidad)

    kb = medicos.map do |m|
      callback_data = "#{m.matricula}|#{m.especialidad}|#{email}"
      [Telegram::Bot::Types::InlineKeyboardButton.new(text: "#{m.nombre} #{m.apellido}", callback_data:)]
    end

    Telegram::Bot::Types::InlineKeyboardMarkup.new(inline_keyboard: kb)
  end
end
