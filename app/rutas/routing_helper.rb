require_relative 'pedir_turno_medico'
require_relative 'pedir_turno_especialidad'

class RoutingHelper
  def self.response_to(routing)
    routing.on_response_to MENSAJE_SELECCIONE_TIPO_RESERVA do |bot, message|
      if message.data == DESHABILITAR
        responder_tipo_reserva_deshabilitado(bot, message)
        next
      end

      case message.data
      when 'pedir_turno_medico'
        TecladoDeshabilitado.disable_keyboard_buttons(bot, message, message.data)
        PedirTurnoMedicoRoutes.pedir_turno(bot, message)
      when 'pedir_turno_especialidad'
        TecladoDeshabilitado.disable_keyboard_buttons(bot, message, message.data)
        PedirTurnoEspecialidadRoutes.pedir_turno(bot, message)
      end
    end
  end

  def self.responder_tipo_reserva_deshabilitado(bot, message)
    bot.api.answer_callback_query(callback_query_id: message.id, text: MENSAJE_TIPO_DE_RESERVA_YA_SELECCIONADO)
  rescue StandardError
    bot.api.send_message(chat_id: message.message.chat.id, text: MENSAJE_ERROR_GENERAL)
  end
end
