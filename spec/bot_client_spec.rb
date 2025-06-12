require 'spec_helper'
require 'web_mock'
require_relative '../app/constantes/mensajes'
require_relative 'stubs/stubs'
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

def registracion_exitosa(email, telegram_id)
  token = 'fake_token'
  when_i_send_text(token, "/registrar #{email}")
  stub_registro(email, telegram_id)
  then_i_get_text(token, 'Registración exitosa')
  BotClient.new(token).run_once
end

def registro_falla_email_en_uso(email, telegram_id)
  token = 'fake_token'
  when_i_send_text(token, "/registrar #{email}")
  stub_email_en_uso(email, telegram_id)
  then_i_get_text(token, 'El email ingresado ya está en uso')
  BotClient.new(token).run_once
end

def registro_falla_paciente_registrado(email, telegram_id)
  token = 'fake_token'
  when_i_send_text(token, "/registrar #{email}")
  stub_paciente_ya_registrado(email, telegram_id)
  then_i_get_text(token, 'Ya se encuentra registrado')
  BotClient.new(token).run_once
end

def expect_mensaje_de_ayuda(token)
  then_i_get_text(token, MENSAJE_AYUDA)
end

describe 'BotClient' do
  let(:opciones_medicos) do
    [
      { text: 'Carlos Sanchez', callback_data: '123|Clinica|pepe@gmail' },
      { text: 'Maria Perez', callback_data: '456|Pediatria|pepe@gmail' },
      { text: 'Juan Ramirez', callback_data: '789|Traumatologia|pepe@gmail' }
    ]
  end

  let(:medicos_disponibles) do
    [
      { 'nombre' => 'Carlos', 'apellido' => 'Sanchez', 'matricula' => '123', 'especialidad' => 'Clinica' },
      { 'nombre' => 'Maria', 'apellido' => 'Perez', 'matricula' => '456', 'especialidad' => 'Pediatria' },
      { 'nombre' => 'Juan', 'apellido' => 'Ramirez', 'matricula' => '789', 'especialidad' => 'Traumatologia' }
    ]
  end

  let(:opciones_turnos) do
    [
      { text: '2023-10-01 - 10:00', callback_data: '2023-10-01|10:00|123|Clinica|pepe@gmail' },
      { text: '2023-10-01 - 11:00', callback_data: '2023-10-01|11:00|123|Clinica|pepe@gmail' },
      { text: '2023-10-01 - 12:00', callback_data: '2023-10-01|12:00|123|Clinica|pepe@gmail' }
    ]
  end

  let(:turnos_disponibles) do
    [
      { 'fecha' => '2023-10-01', 'hora' => '10:00', 'matricula' => '123', 'especialidad' => 'Clinica' },
      { 'fecha' => '2023-10-01', 'hora' => '11:00', 'matricula' => '123', 'especialidad' => 'Clinica' },
      { 'fecha' => '2023-10-01', 'hora' => '12:00', 'matricula' => '123', 'especialidad' => 'Clinica' }
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
    stub_registrado(true)
    stub_medicos_disponibles_exitoso(medicos_disponibles)
    when_i_send_text('fake_token', '/pedir-turno')
    then_i_get_keyboard_message('fake_token', MENSAJE_SELECCIONE_MEDICO, opciones_medicos)

    run_bot_once('fake_token')
  end

  it 'deberia recibir un mensaje /pedir-turno y mostrar un mensaje de error si no esta registrado' do
    stub_registrado(false)
    when_i_send_text('fake_token', '/pedir-turno')
    then_i_get_text('fake_token', MENSAJE_NO_REGISTRADO)
    run_bot_once('fake_token')
  end

  it 'muestra un mensaje de error si la API de médicos falla' do
    stub_registrado(true)
    stub_medicos_disponibles_fallido

    when_i_send_text('fake_token', '/pedir-turno')
    then_i_get_text('fake_token', MENSAJE_ERROR_MEDICOS)

    run_bot_once('fake_token')
  end

  it 'deberia recibir un mensaje Seleccione un Médico y responder con un inline keyboard' do
    token = 'fake_token'
    stub_turnos_disponibles_exitoso(turnos_disponibles, '123')
    when_i_send_keyboard_updates(token, MENSAJE_SELECCIONE_MEDICO, '123|Clinica|pepe@gmail', opciones_medicos)
    then_i_get_keyboard_message(token, MENSAJE_SELECCIONE_TURNO, opciones_turnos)
    run_bot_once(token)
  end

  it 'muestra un mensaje de error si la API de turnos falla' do
    token = 'fake_token'
    stub_turnos_disponibles_fallido
    when_i_send_keyboard_updates(token, MENSAJE_SELECCIONE_MEDICO, '123|Clinica|pepe@gmail', opciones_medicos)
    then_i_get_text(token, MENSAJE_ERROR_TURNOS)
    run_bot_once(token)
  end

  it 'deberia recibir un mensaje Seleccione un turno y responder con un mensaje de confirmación' do
    token = 'fake_token'
    stub_reservar_turno_exitoso
    when_i_send_keyboard_updates(token, MENSAJE_SELECCIONE_TURNO, '2023-10-01|10:00|123|Clinica|pepe@gmail', opciones_turnos)
    then_i_get_text(token, format(MENSAJE_TURNO_CONFIRMADO, fecha: '2023-10-01', hora: '10:00', medico: 'Carlos Sanchez', especialidad: 'Clinica'))
    run_bot_once(token)
  end

  it 'muestra un mensaje de error si la API de reservar turno falla' do
    token = 'fake_token'
    stub_reservar_turno_fallido
    when_i_send_keyboard_updates(token, MENSAJE_SELECCIONE_TURNO, '2023-10-01|10:00|123|Clinica|pepe@gmail', opciones_turnos)
    then_i_get_text(token, MENSAJE_ERROR_RESERVA)
    run_bot_once(token)
  end

  it 'muestra un mensaje de error si se quiere reservar un turno ya reservado' do
    stub_flujo_turno_ya_reservado(turnos_disponibles)
    when_i_send_keyboard_updates('fake_token', MENSAJE_SELECCIONE_TURNO, '2023-10-01|10:00|123|Clinica|pepe@gmail', opciones_turnos)
    then_i_get_text('fake_token', MENSAJE_ERROR_TURNO_EXISTENTE)
    run_bot_once('fake_token')
  end

  it 'deberia recibir un mensaje /pedir-turno y responder con que no hay médicos disponibles' do
    stub_registrado(true)
    stub_medicos_disponibles_exitoso([])
    when_i_send_text('fake_token', '/pedir-turno')
    then_i_get_text('fake_token', MENSAJE_NO_MEDICOS)
    run_bot_once('fake_token')
  end

  it 'deberia recibir un mensaje Seleccione un Médico y responder con un mensaje con que no hay turnos disponibles' do
    stub_turnos_disponibles_fallido_vacio
    when_i_send_keyboard_updates('fake_token', MENSAJE_SELECCIONE_MEDICO, '123|Clinica|pepe@gmail', opciones_medicos)
    then_i_get_text('fake_token', MENSAJE_NO_TURNOS)
    run_bot_once('fake_token')
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

  it 'muestra un mensaje de error si hay un error de conexión al verificar usuario' do
    stub_error_conexion(:get, "/usuarios/telegram/#{USER_ID}")
    when_i_send_text('fake_token', '/pedir-turno')
    then_i_get_text('fake_token', MENSAJE_ERROR_GENERAL)
    run_bot_once('fake_token')
  end

  it 'muestra un mensaje de error si hay un error de conexión al obtener médicos' do
    stub_registrado(true)
    stub_error_conexion(:get, '/turnos/medicos-disponibles')
    when_i_send_text('fake_token', '/pedir-turno')
    then_i_get_text('fake_token', MENSAJE_ERROR_GENERAL)
    run_bot_once('fake_token')
  end

  it 'muestra un mensaje de error si hay un error de conexión al obtener turnos' do
    stub_flujo_turnos_disponibles_con_error_conexion(medicos_disponibles)
    when_i_send_keyboard_updates('fake_token', MENSAJE_SELECCIONE_MEDICO, '123|Clinica|pepe@gmail', opciones_medicos)
    then_i_get_text('fake_token', MENSAJE_ERROR_GENERAL)
    run_bot_once('fake_token')
  end

  it 'muestra un mensaje de error si hay un error de conexión al reservar turno' do
    stub_flujo_reserva_turno_con_error_conexion(medicos_disponibles, turnos_disponibles)
    when_i_send_keyboard_updates('fake_token', MENSAJE_SELECCIONE_TURNO, '2023-10-01|10:00|123|Clinica|pepe@gmail', opciones_turnos)
    then_i_get_text('fake_token', MENSAJE_ERROR_GENERAL)
    run_bot_once('fake_token')
  end

  it 'muestra un mensaje de error si hay un error de conexión al registrar paciente' do
    token = 'fake_token'
    when_i_send_text(token, '/registrar paciente@example.com')
    stub_error_conexion(:post, '/usuarios')
    then_i_get_text(token, MENSAJE_ERROR_GENERAL)
    BotClient.new(token).run_once
  end

  it 'muestra un mensaje de error si hay un error de conexión al verificar si el usuario está registrado' do
    token = 'fake_token'
    stub_error_interno_api(:get, "/usuarios/telegram/#{USER_ID}")
    when_i_send_text(token, '/pedir-turno')
    then_i_get_text(token, MENSAJE_ERROR_GENERAL)
    BotClient.new(token).run_once
  end

  it 'muestra un listado de turnos proximos del paciente' do
    token = 'fake_token'
    stub_turnos_proximos_exitoso
    when_i_send_text(token, '/mis-turnos')
    then_i_get_text(token, "Tus próximos turnos:\nID: 1 - Carlos Sanchez - Clinica - 2023-10-01 10:00\nID: 2 - Maria Perez - Pediatria - 2023-10-02 11:00")
    BotClient.new(token).run_once
  end

  it 'muestra un mensaje de error si no hay turnos proximos' do
    token = 'fake_token'
    stub_turnos_proximos_fallido # vacio
    when_i_send_text(token, '/mis-turnos')
    then_i_get_text(token, MENSAJE_NO_HAY_TURNOS_PROXIMOS)
    BotClient.new(token).run_once
  end

  it 'muestra un mensaje de error si hay un error al obtener turnos proximos' do
    stub_registrado(true)
    stub_error_interno_api(:get, '/turnos/pacientes/proximos/pepe@gmail')
    when_i_send_text('fake_token', '/mis-turnos')
    then_i_get_text('fake_token', MENSAJE_ERROR_API_PROXIMOS_TURNOS)
    BotClient.new('fake_token').run_once
  end

  it 'muestra un mensaje de error si hay un error al obtener turnos proximos por conexion' do
    stub_registrado(true)
    stub_error_conexion(:get, '/turnos/pacientes/proximos/pepe@gmail')
    when_i_send_text('fake_token', '/mis-turnos')
    then_i_get_text('fake_token', MENSAJE_ERROR_GENERAL)
    BotClient.new('fake_token').run_once
  end

  it 'muestra un mensaje si no esta registrado al pedir turnos proximos' do
    stub_registrado(false)
    when_i_send_text('fake_token', '/mis-turnos')
    then_i_get_text('fake_token', MENSAJE_NO_REGISTRADO)
    BotClient.new('fake_token').run_once
  end

  it 'muestra un listado del historial de turnos del paciente' do
    token = 'fake_token'
    stub_historial_turnos_exitoso
    when_i_send_text(token, '/historial-turnos')
    then_i_get_text(token, "Historial de turnos:\nID: 1 - Carlos Sanchez - Clinica - 2023-10-01 10:00 - Ausente\nID: 2 - Maria Perez - Pediatria - 2023-10-02 11:00 - Cancelado")
    BotClient.new(token).run_once
  end

  it 'muestra un mensaje de error si no hay turnos en el historial' do
    token = 'fake_token'
    stub_historial_turnos_vacio
    when_i_send_text(token, '/historial-turnos')
    then_i_get_text(token, MENSAJE_NO_HAY_TURNOS_HISTORIAL)
    BotClient.new(token).run_once
  end

  it 'muestra un mensaje si no esta registrado al pedir historial de turnos' do
    stub_registrado(false)
    when_i_send_text('fake_token', '/historial-turnos')
    then_i_get_text('fake_token', MENSAJE_NO_REGISTRADO)
    BotClient.new('fake_token').run_once
  end
end
