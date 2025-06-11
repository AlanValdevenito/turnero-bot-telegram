require_relative '../constantes/mensajes'
require_relative '../turnero/turnero'
require_relative '../turnero/proveedor_turnero/proveedor_turnero'

class ProximosTurnosRoutes
  def self.register(routing)
    mis_turnos_on_message(routing)
  end

  def self.mis_turnos_on_message(routing)
    routing.on_message '/mis-turnos' do |bot, message|
      handle_error_proximos_turnos(bot, message.chat.id) do
        procesar_mis_turnos(bot, message)
      end
    end
  end

  def self.procesar_mis_turnos(bot, message)
    turnero = Turnero.new(ProveedorTurnero.new(ENV['API_URL']))
    turnero.usuario_registrado?(message.from.id)
    turnos = turnero.proximos_turnos_paciente(message.from.id)
    turnos_mensaje = formatear_turnos_proximos(turnos)
    bot.api.send_message(chat_id: message.chat.id, text: "Tus próximos turnos:\n#{turnos_mensaje}")
  end

  def self.formatear_turnos_proximos(turnos)
    turnos.map do |turno|
      fecha = turno.fecha
      hora = turno.hora
      "ID: #{turno.id} - #{turno.medico.nombre} #{turno.medico.apellido} - #{turno.medico.especialidad} - #{fecha} #{hora}"
    end.join("\n")
  end

  def self.handle_error_proximos_turnos(bot, chat_id)
    yield
  rescue NoHayProximosTurnosException
    bot.api.send_message(chat_id:, text: MENSAJE_NO_HAY_TURNOS_PROXIMOS)
  rescue ErrorAPIProximosTurnosException
    bot.api.send_message(chat_id:, text: MENSAJE_ERROR_API_PROXIMOS_TURNOS)
  rescue ErrorAPIVerificarUsuarioException, ErrorConexionAPI
    bot.api.send_message(chat_id:, text: MENSAJE_ERROR_GENERAL)
  rescue UsuarioNoRegistradoException
    bot.api.send_message(chat_id:, text: MENSAJE_NO_REGISTRADO)
  rescue StandardError => e
    puts "Error completo: #{e.message}"
    bot.api.send_message(chat_id:, text: MENSAJE_ERROR_GENERAL)
  end
end
