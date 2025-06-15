require_relative 'pedir_turno_medico'

class RoutingHelper
  def self.response_to(routing)
    routing.on_response_to MENSAJE_SELECCIONE_TIPO_RESERVA do |bot, message|
      case message.data
      when 'pedir_turno_medico'
        PedirTurnoMedicoRoutes.pedir_turno(bot, message)
      end
    end
  end
end
