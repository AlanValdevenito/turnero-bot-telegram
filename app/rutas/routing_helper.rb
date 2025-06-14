require_relative 'pedir_turno'
require_relative 'errores_turno'

class RoutingHelper
  def self.response_to(routing)
    routing.on_response_to MENSAJE_SELECCIONE_TIPO_RESERVA do |bot, message|
      case message.data
      when 'pedir_turno_medico'
        ErroresTurno.handle_error_pedir_turno(bot, message.from.id) do
          bot.api.send_message(chat_id: message.from.id, text: MENSAJE_SELECCIONE_MEDICO, reply_markup: PedirTurnoRoutes.pedir_turno_por_medico(message.from.id))
        end
      end
    end
  end
end
