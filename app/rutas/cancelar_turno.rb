require_relative '../constantes/mensajes'
require_relative '../turnero/turnero'
require_relative '../turnero/proveedor_turnero/proveedor_turnero'

class CancelarTurnoRoutes
  def self.register(routing)
    cancelar_turno_on_message(routing)
  end

  def self.cancelar_turno_on_message(routing)
    routing.on_message_pattern %r{/cancelar-turno (?<id>.*)} do |bot, message, args|
      procesar_cancelar_turno(bot, message, args['id'])
    end
  end

  def self.procesar_cancelar_turno(bot, message, _id)
    turnero = Turnero.new(ProveedorTurnero.new(ENV['API_URL']))
    email = turnero.usuario_registrado?(message.from.id)
    turnero.cancelar_turno(email)
    bot.api.send_message(chat_id: message.chat.id, text: MENSAJE_TURNO_CANCELADO)
  end
end
