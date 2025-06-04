require 'spec_helper'
require 'web_mock'
# Uncomment to use VCR
# require 'vcr_helper'

require "#{File.dirname(__FILE__)}/../app/bot_client"

ENV['API_URL'] ||= 'http://web:3000'
USER_ID = 141_733_544

def run_bot_once(token)
  app = BotClient.new(token)
  app.run_once
end

def when_i_send_text(token, message_text)
  body = { "ok": true, "result": [{ "update_id": 693_981_718,
                                    "message": { "message_id": 11,
                                                 "from": { "id": USER_ID, "is_bot": false, "first_name": 'Emilio', "last_name": 'Gutter', "username": 'egutter', "language_code": 'en' },
                                                 "chat": { "id": USER_ID, "first_name": 'Emilio', "last_name": 'Gutter', "username": 'egutter', "type": 'private' },
                                                 "date": 1_557_782_998, "text": message_text,
                                                 "entities": [{ "offset": 0, "length": 6, "type": 'bot_command' }] } }] }

  stub_request(:any, "https://api.telegram.org/bot#{token}/getUpdates")
    .to_return(body: body.to_json, status: 200, headers: { 'Content-Length' => 3 })
end

def when_i_send_keyboard_updates(token, message_text, inline_selection, buttons = nil)
  buttons ||= [
    { 'text' => 'Jon Snow', 'callback_data' => '1' },
    { 'text' => 'Daenerys Targaryen', 'callback_data' => '2' },
    { 'text' => 'Ned Stark', 'callback_data' => '3' }
  ]
  buttons = buttons.map { |btn| [btn] } if buttons.any? && !buttons.first.is_a?(Array)

  body = {
    "ok": true, "result": [{
      "update_id": 866_033_907,
      "callback_query": {
        "id": '608740940475689651',
        "from": { "id": USER_ID, "is_bot": false, "first_name": 'Emilio', "last_name": 'Gutter', "username": 'egutter', "language_code": 'en' },
        "message": {
          "message_id": 626,
          "from": { "id": 715_612_264, "is_bot": true, "first_name": 'fiuba-memo2-prueba', "username": 'fiuba_memo2_bot' },
          "chat": { "id": USER_ID, "first_name": 'Emilio', "last_name": 'Gutter', "username": 'egutter', "type": 'private' },
          "date": 1_595_282_006,
          "text": message_text,
          "reply_markup": { "inline_keyboard": buttons }
        },
        "chat_instance": '2671782303129352872',
        "data": inline_selection
      }
    }]
  }

  stub_request(:any, "https://api.telegram.org/bot#{token}/getUpdates")
    .to_return(body: body.to_json, status: 200, headers: { 'Content-Length' => 3 })
end

def then_i_get_text(token, message_text)
  body = { "ok": true,
           "result": { "message_id": 12,
                       "from": { "id": 715_612_264, "is_bot": true, "first_name": 'fiuba-memo2-prueba', "username": 'fiuba_memo2_bot' },
                       "chat": { "id": USER_ID, "first_name": 'Emilio', "last_name": 'Gutter', "username": 'egutter', "type": 'private' },
                       "date": 1_557_782_999, "text": message_text } }

  stub_request(:post, "https://api.telegram.org/bot#{token}/sendMessage")
    .with(
      body: { 'chat_id' => '141733544', 'text' => message_text }
    )
    .to_return(status: 200, body: body.to_json, headers: {})
end

def then_i_get_keyboard_message(token, message_text, options = nil)
  # options: array de hashes [{text: 'Jon Snow', callback_data: '1'}, ...]

  inline_keyboard = options.map { |opt| [{ 'text' => opt[:text], 'callback_data' => opt[:callback_data] }] }
  reply_markup = { 'inline_keyboard' => inline_keyboard }.to_json

  body = { "ok": true,
           "result": { "message_id": 12,
                       "from": { "id": 715_612_264, "is_bot": true, "first_name": 'fiuba-memo2-prueba', "username": 'fiuba_memo2_bot' },
                       "chat": { "id": USER_ID, "first_name": 'Emilio', "last_name": 'Gutter', "username": 'egutter', "type": 'private' },
                       "date": 1_557_782_999, "text": message_text } }

  stub_request(:post, "https://api.telegram.org/bot#{token}/sendMessage")
    .with(
      body: {
        'chat_id' => USER_ID.to_s,
        'reply_markup' => reply_markup,
        'text' => message_text
      }
    )
    .to_return(status: 200, body: body.to_json, headers: {})
end

def stub_api
  api_response_body = { "version": '0.0.1' }
  stub_request(:get, "#{ENV['API_URL']}/version")
    .with(
      headers: {
        'Accept' => '*/*',
        'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
        'User-Agent' => 'Faraday v2.7.4'
      }
    ).to_return(status: 200, body: api_response_body.to_json, headers: {})
end

def stub_registro(email, telegram_id)
  stub_request(:post, "#{ENV['API_URL']}/usuarios")
    .with(
      body: { email:, telegram_id: }.to_json,
      headers: { 'Content-Type' => 'application/json' }
    ).to_return(status: 200, body: { id: 123, email: }.to_json)
end

def registracion_exitosa(email, telegram_id)
  token = 'fake_token'
  when_i_send_text(token, "/registrar #{email}")
  stub_registro(email, telegram_id)
  then_i_get_text(token, 'Registración exitosa')
  BotClient.new(token).run_once
end

def stub_email_en_uso(email, telegram_id)
  stub_request(:post, "#{ENV['API_URL']}/usuarios")
    .with(
      body: { email:, telegram_id: }.to_json,
      headers: { 'Content-Type' => 'application/json' }
    ).to_return(status: 400, body: { error: 'El email ingresado ya está en uso' }.to_json)
end

def registro_falla_email_en_uso(email, telegram_id)
  token = 'fake_token'
  when_i_send_text(token, "/registrar #{email}")
  stub_email_en_uso(email, telegram_id)
  then_i_get_text(token, 'El email ingresado ya está en uso')
  BotClient.new(token).run_once
end

def stub_paciente_ya_registrado(email, telegram_id)
  stub_request(:post, "#{ENV['API_URL']}/usuarios")
    .with(
      body: { email:, telegram_id: }.to_json,
      headers: { 'Content-Type' => 'application/json' }
    ).to_return(status: 400, body: { error: 'El paciente ya se encuentra registrado' }.to_json)
end

def registro_falla_paciente_registrado(email, telegram_id)
  token = 'fake_token'
  when_i_send_text(token, "/registrar #{email}")
  stub_paciente_ya_registrado(email, telegram_id)
  then_i_get_text(token, 'El paciente ya se encuentra registrado')
  BotClient.new(token).run_once
end

def expect_mensaje_de_ayuda(token)
  then_i_get_text(token, <<~TEXT)
    Comandos disponibles:
    /registrar {email} - Registra tu email en el sistema
  TEXT
end

def stub_medicos_disponibles_exitoso(medicos)
  stub_request(:get, "#{ENV['API_URL']}/turnos/medicos-disponibles")
    .to_return(status: 200, body: medicos.to_json, headers: { 'Content-Type' => 'application/json' })
end

def stub_medicos_disponibles_fallidos
  stub_request(:get, "#{ENV['API_URL']}/turnos/medicos-disponibles")
    .to_return(status: 500, body: { error: 'Error interno' }.to_json, headers: { 'Content-Type' => 'application/json' })
end

describe 'BotClient' do
  let(:opciones_medicos) do
    [
      { text: 'Carlos Sanchez', callback_data: 'turnos_medico:123-Clinica' },
      { text: 'Maria Perez', callback_data: 'turnos_medico:456-Pediatria' },
      { text: 'Juan Ramirez', callback_data: 'turnos_medico:789-Traumatologia' }
    ]
  end

  let(:medicos_disponibles) do
    [
      { 'nombre' => 'Carlos', 'apellido' => 'Sanchez', 'matricula' => '123', 'especialidad' => 'Clinica' },
      { 'nombre' => 'Maria', 'apellido' => 'Perez', 'matricula' => '456', 'especialidad' => 'Pediatria' },
      { 'nombre' => 'Juan', 'apellido' => 'Ramirez', 'matricula' => '789', 'especialidad' => 'Traumatologia' }
    ]
  end

  it 'should get a /version message and respond with current version' do
    stub_api
    when_i_send_text('fake_token', '/version')
    then_i_get_text('fake_token', "Bot version: #{Version.current} - Api Version: 0.0.1")

    app = BotClient.new('fake_token')

    app.run_once
  end

  it 'should get a /say_hi message and respond with Hola Emilio' do
    token = 'fake_token'

    when_i_send_text(token, '/say_hi Emilio')
    then_i_get_text(token, 'Hola, Emilio')

    run_bot_once(token)
  end

  it 'should get a /start message and respond with Hola' do
    token = 'fake_token'

    when_i_send_text(token, '/start')
    then_i_get_text(token, 'Hola, Emilio')

    run_bot_once(token)
  end

  it 'deberia recibir un mensaje /pedir-turno y responder con un inline keyboard' do
    token = 'fake_token'
    stub_medicos_disponibles_exitoso(medicos_disponibles)
    when_i_send_text(token, '/pedir-turno')
    then_i_get_keyboard_message(token, 'Seleccione un Médico', opciones_medicos)

    run_bot_once(token)
  end

  it 'muestra un mensaje de error si la API de médicos falla' do
    token = 'fake_token'
    stub_medicos_disponibles_fallidos

    when_i_send_text(token, '/pedir-turno')
    then_i_get_text(token, 'Error al obtener la lista de médicos disponibles')

    run_bot_once(token)
  end

  xit 'deberia recibir un mensaje Seleccione un Médico y responder con un inline keyboard' do
    token = 'fake_token'
    when_i_send_keyboard_updates(token, 'Seleccione un Médico', 'turnos_medico:123-Clinica', opciones_medicos)
    then_i_get_keyboard_message(token, 'Seleccione un Turno', opciones_turnos)
    run_bot_once(token)
  end

  it 'should get a /stop message and respond with Chau' do
    token = 'fake_token'

    when_i_send_text(token, '/stop')
    then_i_get_text(token, 'Chau, egutter')

    run_bot_once(token)
  end

  it 'should get an unknown message and respond with help message' do
    token = 'fake_token'

    when_i_send_text(token, '/unknown')
    expect_mensaje_de_ayuda(token)

    BotClient.new(token).run_once
  end

  it 'should register a patient and respond with success message' do
    email = 'paciente@example.com'
    registracion_exitosa(email, USER_ID)
  end

  it 'should show an error if email is already in use' do
    email = 'duplicado@example.com'
    registro_falla_email_en_uso(email, USER_ID)
  end

  it 'should show an error if patient is already registered' do
    email = 'registrado@example.com'
    registro_falla_paciente_registrado(email, USER_ID)
  end
end
