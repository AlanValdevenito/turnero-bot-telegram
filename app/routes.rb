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

  on_message '/tv' do |bot, message|
    kb = [Tv::Series.all.map do |tv_serie|
      Telegram::Bot::Types::InlineKeyboardButton.new(text: tv_serie.name, callback_data: tv_serie.id.to_s)
    end]
    markup = Telegram::Bot::Types::InlineKeyboardMarkup.new(inline_keyboard: kb)

    bot.api.send_message(chat_id: message.chat.id, text: 'Quien se queda con el trono?', reply_markup: markup)
  end

  on_message '/busqueda_centro' do |bot, message|
    kb = [[
      Telegram::Bot::Types::KeyboardButton.new(text: 'Compartime tu ubicacion', request_location: true)
    ]]
    markup = Telegram::Bot::Types::ReplyKeyboardMarkup.new(keyboard: kb)
    bot.api.send_message(chat_id: message.chat.id, text: 'Busqueda por ubicacion', reply_markup: markup)
  end

  on_location_response do |bot, message|
    response = "Ubicacion es Lat:#{message.location.latitude} - Long:#{message.location.longitude}"
    puts response
    bot.api.send_message(chat_id: message.chat.id, text: response)
  end

  on_response_to 'Quien se queda con el trono?' do |bot, message|
    response = Tv::Series.handle_response message.data
    bot.api.send_message(chat_id: message.message.chat.id, text: response)
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
    proveedor = ProveedorTurnero.new(ENV['API_URL'])
    medicos = proveedor.solicitar_medicos_disponibles

    kb = [medicos.map.with_index(1) do |m, i|
      Telegram::Bot::Types::InlineKeyboardButton.new(
        text: "#{i}. #{m['nombre']} #{m['apellido']}",
        callback_data: "turnos_medico:#{m['matricula']}-#{m['especialidad']}"
      )
    end]
    markup = Telegram::Bot::Types::InlineKeyboardMarkup.new(inline_keyboard: kb)
    bot.api.send_message(chat_id: message.chat.id, text: 'Seleccione un Médico', reply_markup: markup)
  rescue ErrorAPIMedicosDisponiblesException
    bot.api.send_message(chat_id: message.chat.id, text: 'Error al obtener la lista de médicos disponibles')
  end

  default do |bot, message|
    help_text = <<~TEXT
      Comandos disponibles:
      /registrar {email} - Registra tu email en el sistema
    TEXT

    bot.api.send_message(chat_id: message.chat.id, text: help_text)
  end
end
