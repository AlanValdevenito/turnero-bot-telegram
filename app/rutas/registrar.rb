require_relative '../constantes/mensajes'
require_relative '../turnero/excepciones/index'
require_relative '../turnero/turnero'
require_relative '../turnero/proveedor_turnero/proveedor_turnero'

class RegistrarRoutes
  def self.register(routing)
    routing.on_message_pattern %r{/registrar (?<email>.*)} do |bot, message, args|
      handle_error_registrar(bot, message.chat.id) do
        bot.logger.debug("/registrar: #{args}")
        registrar_paciente(bot, message, args)
      end
    end
  end

  def self.registrar_paciente(bot, message, args)
    email = args['email']
    turnero = Turnero.new(ProveedorTurnero.new(ENV['API_URL'], ENV['API_KEY']))
    turnero.registrar_paciente(email, message.from.id)
    bot.api.send_message(chat_id: message.chat.id, text: MENSAJE_REGISTRO_EXITOSO)
  end

  def self.handle_error_registrar(bot, chat_id)
    yield
  rescue EmailYaEnUsoException
    bot.api.send_message(chat_id:, text: MENSAJE_EMAIL_EN_USO)
  rescue PacienteYaRegistradoException
    bot.api.send_message(chat_id:, text: MENSAJE_YA_REGISTRADO)
  rescue ErrorConexionAPI
    bot.api.send_message(chat_id:, text: MENSAJE_ERROR_GENERAL)
  rescue StandardError => e
    puts "Error completo: #{e.message}"
    bot.api.send_message(chat_id:, text: MENSAJE_ERROR_GENERAL)
  end
end
