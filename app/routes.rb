require "#{File.dirname(__FILE__)}/../lib/routing"
require "#{File.dirname(__FILE__)}/../lib/version"
require "#{File.dirname(__FILE__)}/tv/series"
require "#{File.dirname(__FILE__)}/turnero/turnero"
require "#{File.dirname(__FILE__)}/turnero/proveedor_turnero"
require "#{File.dirname(__FILE__)}/turnero/excepciones/email_en_uso_exception"

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

  on_message '/time' do |bot, message|
    bot.api.send_message(chat_id: message.chat.id, text: "La hora es, #{Time.now}")
  end

  on_message '/version' do |bot, message|
    response_version = Faraday.new("#{ENV['API_URL']}/version").get
    api_version = JSON.parse(response_version.body)['version']
    response = "Bot version: #{Version.current} - Api Version: #{api_version}"
    bot.api.send_message(chat_id: message.chat.id, text: response)
  end

  on_message_pattern %r{/registrar (?<email>.*)} do |bot, message, args|
    email = args['email']
    telegram_id = message.from.id
    turnero = Turnero.new(ProveedorTurnero.new(ENV['API_URL']))
    begin
      turnero.registrar_paciente(email, telegram_id)
      bot.api.send_message(chat_id: message.chat.id, text: 'Registración exitosa')
    rescue EmailYaEnUsoException
      bot.api.send_message(chat_id: message.chat.id, text: 'El email ingresado ya está en uso')
    rescue PacienteYaRegistradoException
      bot.api.send_message(chat_id: message.chat.id, text: 'El paciente ya se encuentra registrado')
    rescue StandardError => e
      puts "Error completo: #{e.message}"
      bot.api.send_message(chat_id: message.chat.id, text: 'Error al registrar el paciente')
    end
  end

  on_message '/pedir-turno' do |bot, message|
    turnero = Turnero.new(ProveedorTurnero.new(ENV['API_URL']))
    unless turnero.usuario_registrado?(message.from.id)
      bot.api.send_message(chat_id: message.chat.id, text: 'Debe registrarse primero usando el comando /registrar {email}')
      next
    end
    medicos = turnero.solicitar_medicos_disponibles

    kb = medicos.map do |m|
      [Telegram::Bot::Types::InlineKeyboardButton.new(
        text: "#{m['nombre']} #{m['apellido']}",
        callback_data: "turnos_medico:#{m['matricula']}-#{m['especialidad']}"
      )]
    end
    markup = Telegram::Bot::Types::InlineKeyboardMarkup.new(inline_keyboard: kb)
    bot.api.send_message(chat_id: message.chat.id, text: 'Seleccione un Médico', reply_markup: markup)
  rescue NoHayMedicosDisponiblesException
    bot.api.send_message(chat_id: message.chat.id, text: 'No hay médicos disponibles en este momento')
  rescue ErrorAPIMedicosDisponiblesException
    bot.api.send_message(chat_id: message.chat.id, text: 'Error al obtener la lista de médicos disponibles')
  end

  on_response_to 'Seleccione un Médico' do |bot, message|
    turnero = Turnero.new(ProveedorTurnero.new(ENV['API_URL']))
    matricula, especialidad = message.data.split(':').last.split('-')
    begin
      turnos = turnero.solicitar_turnos_disponibles(matricula, especialidad)
      kb = turnos.map do |t|
        [
          Telegram::Bot::Types::InlineKeyboardButton.new(
            text: "#{t['fecha']} - #{t['hora']}",
            callback_data: "turno_seleccionado:#{t['fecha']}-#{t['hora']}-#{matricula}-#{especialidad}-#{message.from.id}"
          )
        ]
      end
      markup = Telegram::Bot::Types::InlineKeyboardMarkup.new(inline_keyboard: kb)
      bot.api.send_message(chat_id: message.message.chat.id, text: 'Seleccione un turno', reply_markup: markup)
    rescue ErrorAPITurnosDisponiblesException
      bot.api.send_message(chat_id: message.message.chat.id, text: 'Error al obtener los turnos disponibles')
    end
  end

  on_response_to 'Seleccione un turno' do |bot, message|
    turnero = Turnero.new(ProveedorTurnero.new(ENV['API_URL']))
    puts "Datos del mensaje: #{message.data}"
    data = message.data.split(':', 2).last.split('-')
    fecha = data[0..2].join('-') # "2025-06-05"
    hora = data[3]               # "08:10"
    matricula = data[4]          # "92"
    especialidad = data[5]       # "Traumatologia"
    telegram_id = data[6]        # "7158408552"
    turno = turnero.reservar_turno(matricula, fecha, hora, telegram_id)
    puts "Turno reservado: #{turno.inspect}"
    response = "Turno reservado exitosamente:\nFecha: #{turno['fecha']}\nHora: #{turno['hora']}\nMédico: #{turno['medico']['nombre']} #{turno['medico']['apellido']}\nEspecialidad: #{especialidad}"
    bot.api.send_message(chat_id: message.message.chat.id, text: response)
  rescue ErrorAPIReservarTurnoException
    bot.api.send_message(chat_id: message.message.chat.id, text: 'Error al reservar el turno')
  end

  default do |bot, message|
    help_text = <<~TEXT
      Comandos disponibles:
      /registrar {email} - Registra tu email en el sistema
      /pedir-turno - Solicita un turno médico
    TEXT

    bot.api.send_message(chat_id: message.chat.id, text: help_text)
  end
end
