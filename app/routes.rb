require "#{File.dirname(__FILE__)}/../lib/routing"
require "#{File.dirname(__FILE__)}/../lib/version"
require "#{File.dirname(__FILE__)}/tv/series"
require "#{File.dirname(__FILE__)}/turnero/turnero"
require "#{File.dirname(__FILE__)}/turnero/proveedor_turnero/proveedor_turnero"
require_relative 'constantes/mensajes'

class Routes
  include Routing

  on_message '/start' do |bot, message|
    bot.api.send_message(chat_id: message.chat.id, text: "Hola, #{message.from.first_name}")
  end

  on_message_pattern %r{/say_hi (?<name>.*)} do |bot, message, args|
    bot.api.send_message(chat_id: message.chat.id, text: "Hola, #{args['name']}")
  end

  on_message '/stop' do |bot, message|
    bot.api.send_message(chat_id: message.chat.id, text: "Chau, #{message.from.username}")
  end

  on_message '/version' do |bot, message|
    response_version = Faraday.new("#{ENV['API_URL']}/version").get
    api_version = JSON.parse(response_version.body)['version']
    response = "Bot version: #{Version.current} - Api Version: #{api_version}"
    bot.api.send_message(chat_id: message.chat.id, text: response)
  end

  on_message_pattern %r{/registrar (?<email>.*)} do |bot, message, args|
    email = args['email']
    turnero = Turnero.new(ProveedorTurnero.new(ENV['API_URL']))
    begin
      turnero.registrar_paciente(email, message.from.id)
      bot.api.send_message(chat_id: message.chat.id, text: MENSAJE_REGISTRO_EXITOSO)
    rescue EmailYaEnUsoException
      bot.api.send_message(chat_id: message.chat.id, text: MENSAJE_EMAIL_EN_USO)
    rescue PacienteYaRegistradoException
      bot.api.send_message(chat_id: message.chat.id, text: MENSAJE_YA_REGISTRADO)
    rescue ErrorConexionAPI
      bot.api.send_message(chat_id: message.chat.id, text: MENSAJE_ERROR_GENERAL)
    rescue StandardError => e
      puts "Error completo: #{e.message}"
      bot.api.send_message(chat_id: message.chat.id, text: MENSAJE_ERROR_GENERAL)
    end
  end

  on_message '/pedir-turno' do |bot, message|
    turnero = Turnero.new(ProveedorTurnero.new(ENV['API_URL']))
    unless turnero.usuario_registrado?(message.from.id)
      bot.api.send_message(chat_id: message.chat.id, text: MENSAJE_NO_REGISTRADO)
      next
    end
    medicos = turnero.solicitar_medicos_disponibles
    kb = medicos.map do |m|
      callback_data = "#{m.matricula}-#{m.especialidad}"
      [Telegram::Bot::Types::InlineKeyboardButton.new(text: "#{m.nombre} #{m.apellido}", callback_data:)]
    end
    markup = Telegram::Bot::Types::InlineKeyboardMarkup.new(inline_keyboard: kb)
    bot.api.send_message(chat_id: message.chat.id, text: MENSAJE_SELECCIONE_MEDICO, reply_markup: markup)
  rescue NoHayMedicosDisponiblesException
    bot.api.send_message(chat_id: message.chat.id, text: MENSAJE_NO_MEDICOS)
  rescue ErrorAPIMedicosDisponiblesException
    bot.api.send_message(chat_id: message.chat.id, text: MENSAJE_ERROR_MEDICOS)
  rescue ErrorAPIVerificarUsuarioException, ErrorConexionAPI
    bot.api.send_message(chat_id: message.chat.id, text: MENSAJE_ERROR_GENERAL)
  end

  on_response_to MENSAJE_SELECCIONE_MEDICO do |bot, message|
    turnero = Turnero.new(ProveedorTurnero.new(ENV['API_URL']))
    matricula, especialidad = message.data.split('-')
    begin
      turnos = turnero.solicitar_turnos_disponibles(matricula, especialidad)
      kb = turnos.map do |t|
        callback_data = "#{t['fecha']}-#{t['hora']}-#{matricula}-#{especialidad}-#{message.from.id}"
        [
          Telegram::Bot::Types::InlineKeyboardButton.new(
            text: "#{t['fecha']} - #{t['hora']}",
            callback_data:
          )
        ]
      end
      markup = Telegram::Bot::Types::InlineKeyboardMarkup.new(inline_keyboard: kb)
      bot.api.send_message(chat_id: message.message.chat.id, text: MENSAJE_SELECCIONE_TURNO, reply_markup: markup)
    rescue NohayTurnosDisponiblesException
      bot.api.send_message(chat_id: message.message.chat.id, text: MENSAJE_NO_TURNOS)
    rescue ErrorAPITurnosDisponiblesException
      bot.api.send_message(chat_id: message.message.chat.id, text: MENSAJE_ERROR_TURNOS)
    rescue ErrorConexionAPI
      bot.api.send_message(chat_id: message.message.chat.id, text: MENSAJE_ERROR_GENERAL)
    end
  end

  on_response_to MENSAJE_SELECCIONE_TURNO do |bot, message|
    turnero = Turnero.new(ProveedorTurnero.new(ENV['API_URL']))
    data = message.data.split('-')
    fecha = data[0..2].join('-') # "2025-06-05"
    hora = data[3]               # "08:10"
    matricula = data[4]          # "92"
    especialidad = data[5]       # "Traumatologia"
    telegram_id = data[6]        # "7158408552"
    turno = turnero.reservar_turno(matricula, fecha, hora, telegram_id)
    response = format(MENSAJE_TURNO_CONFIRMADO, fecha: turno['fecha'], hora: turno['hora'], medico: "#{turno['medico']['nombre']} #{turno['medico']['apellido']}", especialidad:)
    bot.api.send_message(chat_id: message.message.chat.id, text: response)
  rescue TurnoYaExisteException
    bot.api.send_message(chat_id: message.message.chat.id, text: MENSAJE_ERROR_TURNO_EXISTENTE)
  rescue ErrorAPIReservarTurnoException
    bot.api.send_message(chat_id: message.message.chat.id, text: MENSAJE_ERROR_RESERVA)
  rescue ErrorConexionAPI
    bot.api.send_message(chat_id: message.message.chat.id, text: MENSAJE_ERROR_GENERAL)
  end

  default do |bot, message|
    help_text = MENSAJE_AYUDA
    bot.api.send_message(chat_id: message.chat.id, text: help_text)
  end
end
