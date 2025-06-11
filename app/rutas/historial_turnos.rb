require_relative '../constantes/mensajes'
require_relative '../turnero/turnero'
require_relative '../turnero/proveedor_turnero/proveedor_turnero'

class HistorialTurnosRoutes
  def self.register(routing)
    historial_turnos_on_message(routing)
  end

  def self.historial_turnos_on_message(routing)
    routing.on_message '/historial-turnos' do |bot, message|
      turnero = Turnero.new(ProveedorTurnero.new(ENV['API_URL']))
      turnero.usuario_registrado?(message.from.id)
      turnos = turnero.historial_turnos_paciente(message.from.id)
      turnos_mensaje = formatear_turnos_proximos(turnos)
      bot.api.send_message(chat_id: message.chat.id, text: "Tus próximos turnos:\n#{turnos_mensaje}")
    end
  end

  def self.formatear_historial_turnos(turnos)
    turnos.map do |turno|
      fecha = turno.fecha
      hora = turno.hora
      "ID: #{turno.id} - #{turno.medico.nombre} #{turno.medico.apellido} - #{turno.medico.especialidad} - #{fecha} #{hora} - #{turno.estado}"
    end.join("\n")
  end
end
