require_relative '../constantes/mensajes'
require_relative '../turnero/turnero'
require_relative '../turnero/proveedor_turnero/proveedor_turnero'

class ProximosTurnosRoutes
  def self.register(routing)
    mis_turnos_on_message(routing)
  end

  def self.mis_turnos_on_message(routing)
    routing.on_message '/mis-turnos' do |bot, message|
      telegram_id = message.from.id
      turnero = Turnero.new(ProveedorTurnero.new(ENV['API_URL']))
      turnero.usuario_registrado?(telegram_id)
      turnos = turnero.proximos_turnos_paciente(telegram_id)
      turnos_mensaje = formatear_turnos_proximos(turnos)
      bot.api.send_message(chat_id: message.chat.id, text: "Tus próximos turnos:\n#{turnos_mensaje}")
    end
  end

  def self.formatear_turnos_proximos(turnos)
    turnos.map do |turno|
      "#{turno.fecha_hora.strftime('%Y-%m-%d %H:%M')} - #{turno.medico.nombre} #{turno.medico.apellido} - #{turno.medico.especialidad.nombre} - ID: #{turno.id}"
    end.join("\n")
  end
end
