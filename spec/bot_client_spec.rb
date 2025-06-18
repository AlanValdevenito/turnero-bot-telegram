require 'spec_helper'
require 'web_mock'
require_relative '../app/constantes/mensajes'
require_relative 'stubs/stubs'

require "#{File.dirname(__FILE__)}/../app/bot_client"
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

def then_i_get_callback_alert(token, alert_text)
  body = { "ok": true }

  stub_request(:post, "https://api.telegram.org/bot#{token}/answerCallbackQuery")
    .with(
      body: hash_including({ 'text' => alert_text })
    )
    .to_return(status: 200, body: body.to_json, headers: {})
end

def then_keyboard_is_updated(token)
  stub_request(:post, "https://api.telegram.org/bot#{token}/editMessageReplyMarkup")
    .to_return(status: 200, body: { "ok": true }.to_json, headers: {})
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

  let(:opciones_tipo_reserva) do
    [
      { text: 'Por especialidad', callback_data: 'e|pepe@gmail' },
      { text: 'Por medico', callback_data: 'm|pepe@gmail' }
    ]
  end

  def opciones_especialidades
    [
      { text: 'Clinica', callback_data: 'Clinica|pepe@gmail' },
      { text: 'Dermatologia', callback_data: 'Dermatologia|pepe@gmail' }
    ]
  end

  def opciones_confirmacion
    [
      { text: 'Si', callback_data: 'true|1|pepe@gmail' },
      { text: 'No', callback_data: 'false|1|pepe@gmail' }
    ]
  end

  def medicos_por_especialidad_disponibles
    [
      { 'nombre' => 'Carlos', 'apellido' => 'Sanchez', 'matricula' => '123', 'especialidad' => 'Clinica' },
      { 'nombre' => 'Maria', 'apellido' => 'Perez', 'matricula' => '456', 'especialidad' => 'Clinica' },
      { 'nombre' => 'Juan', 'apellido' => 'Ramirez', 'matricula' => '789', 'especialidad' => 'Clinica' }
    ]
  end

  def setup_y_espera_inline_keyboard_turnos(token, mensaje, seleccion, opciones_medicos, opciones_turnos)
    stub_turnos_disponibles_exitoso(turnos_disponibles, '123')

    stub_request(:post, "https://api.telegram.org/bot#{token}/editMessageReplyMarkup")
      .to_return(status: 200, body: { "ok": true }.to_json, headers: {})

    stub_request(:post, "https://api.telegram.org/bot#{token}/answerCallbackQuery")
      .with(body: hash_including({ 'callback_query_id' => '608740940475689651' }))
      .to_return(status: 200, body: { "ok": true }.to_json, headers: {})

    when_i_send_keyboard_updates(token, mensaje, seleccion, opciones_medicos)
    then_i_get_keyboard_message(token, MENSAJE_SELECCIONE_TURNO, opciones_turnos)
  end

  def setup_y_espera_inline_keyboard_medicos_por_especialidad(token, mensaje, seleccion, opciones_especialidades, opciones_medicos)
    stub_medicos_por_especialidad_disponibles_exitoso(medicos_por_especialidad_disponibles, 'Clinica')

    stub_request(:post, "https://api.telegram.org/bot#{token}/editMessageReplyMarkup")
      .to_return(status: 200, body: { "ok": true }.to_json, headers: {})

    stub_request(:post, "https://api.telegram.org/bot#{token}/answerCallbackQuery")
      .with(body: hash_including({ 'callback_query_id' => '608740940475689651' }))
      .to_return(status: 200, body: { "ok": true }.to_json, headers: {})

    when_i_send_keyboard_updates(token, mensaje, seleccion, opciones_especialidades)
    then_i_get_keyboard_message(token, MENSAJE_SELECCIONE_MEDICO, opciones_medicos)

    setup_y_espera_inline_keyboard_turnos(token, MENSAJE_SELECCIONE_MEDICO, '123|Clinica|pepe@gmail', opciones_medicos, opciones_turnos)
  end

  def setup_cancelacion_sin_anticipacion(token, mensaje, seleccion, opciones)
    stub_cancelar_turno_sin_anticipacion(1, 'pepe@gmail', false)
    stub_cancelar_turno_sin_anticipacion(1, 'pepe@gmail', true)
    when_i_send_text(token, '/cancelar-turno 1')
    then_i_get_keyboard_message(token, mensaje, opciones)
    when_i_send_keyboard_updates(token, mensaje, seleccion, opciones)
  end

  def setup_turnos_fallidos(token, mensaje, seleccion, opciones)
    stub_turnos_disponibles_fallido

    stub_request(:post, "https://api.telegram.org/bot#{token}/editMessageReplyMarkup")
      .to_return(status: 200, body: { "ok": true }.to_json, headers: {})

    stub_request(:post, "https://api.telegram.org/bot#{token}/answerCallbackQuery")
      .with(body: hash_including({ 'callback_query_id' => '608740940475689651' }))
      .to_return(status: 200, body: { "ok": true }.to_json, headers: {})

    when_i_send_keyboard_updates(token, mensaje, seleccion, opciones)
  end

  def stub_edit_message_reply_markup_turno(token)
    reply_markup = {
      'inline_keyboard' => [
        [{ 'text' => '[ 2023-10-01 - 10:00 ]', 'callback_data' => 'disabled' }],
        [{ 'text' => '2023-10-01 - 11:00', 'callback_data' => 'disabled' }],
        [{ 'text' => '2023-10-01 - 12:00', 'callback_data' => 'disabled' }]
      ]
    }.to_json

    stub_request(:post, "https://api.telegram.org/bot#{token}/editMessageReplyMarkup")
      .with(
        body: {
          'chat_id' => '141733544',
          'message_id' => '626',
          'reply_markup' => reply_markup
        }
      )
      .to_return(status: 200, body: '{"ok":true,"result":{}}', headers: {})
  end

  def setup_turno_confirmacion(token)
    stub_reservar_turno_exitoso
    stub_edit_message_reply_markup_turno(token)
  end

  def setup_reserva_turno_fallida(token)
    stub_reservar_turno_fallido
    stub_edit_message_reply_markup_turno(token)
  end

  def setup_turno_ya_reservado(token)
    stub_flujo_turno_ya_reservado(turnos_disponibles)
    stub_edit_message_reply_markup_turno(token)
  end

  def setup_turno_superpuesto(token)
    stub_flujo_turno_superpuesto(turnos_disponibles)
    stub_edit_message_reply_markup_turno(token)
  end

  def setup_reserva_turno_penalizado(token)
    stub_flujo_turno_penalizacion(turnos_disponibles)
    stub_edit_message_reply_markup_turno(token)
  end

  def setup_sin_turnos_disponibles(token, mensaje, seleccion, opciones)
    stub_turnos_disponibles_fallido_vacio

    stub_request(:post, "https://api.telegram.org/bot#{token}/editMessageReplyMarkup")
      .to_return(status: 200, body: { "ok": true }.to_json, headers: {})

    stub_request(:post, "https://api.telegram.org/bot#{token}/answerCallbackQuery")
      .with(body: hash_including({ 'callback_query_id' => '608740940475689651' }))
      .to_return(status: 200, body: { "ok": true }.to_json, headers: {})

    when_i_send_keyboard_updates(token, mensaje, seleccion, opciones)
  end

  def setup_sin_medicos_por_especialidad_disponibles(token, mensaje, seleccion, opciones)
    stub_medicos_por_especialidad_disponibles_fallido('Clinica')

    stub_request(:post, "https://api.telegram.org/bot#{token}/editMessageReplyMarkup")
      .to_return(status: 200, body: { "ok": true }.to_json, headers: {})

    stub_request(:post, "https://api.telegram.org/bot#{token}/answerCallbackQuery")
      .with(body: hash_including({ 'callback_query_id' => '608740940475689651' }))
      .to_return(status: 200, body: { "ok": true }.to_json, headers: {})

    when_i_send_keyboard_updates(token, mensaje, seleccion, opciones)
  end

  def then_keyboard_is_updated(token, callback_query_id = '608740940475689651')
    stub_request(:post, "https://api.telegram.org/bot#{token}/editMessageReplyMarkup")
      .with(
        body: hash_including({
                               'chat_id' => USER_ID.to_s,
                               'message_id' => '626'
                             })
      )
      .to_return(status: 200, body: { "ok": true }.to_json, headers: {})

    stub_request(:post, "https://api.telegram.org/bot#{token}/answerCallbackQuery")
      .with(body: hash_including({ 'callback_query_id' => callback_query_id }))
      .to_return(status: 200, body: { "ok": true }.to_json, headers: {})
  end

  def setup_reserva_turno_con_error_conexion(token)
    stub_flujo_reserva_turno_con_error_conexion(medicos_disponibles, turnos_disponibles)
    stub_edit_message_reply_markup_turno(token)
  end

  def cuando_pido_reservar_turno_por_medico(token)
    stub_request(:post, "https://api.telegram.org/bot#{token}/editMessageReplyMarkup")
      .with(
        body: hash_including({
                               'chat_id' => USER_ID.to_s,
                               'message_id' => '626'
                             })
      )
      .to_return(status: 200, body: { "ok": true }.to_json, headers: {})

    when_i_send_text(token, '/pedir-turno')
    then_i_get_keyboard_message(token, MENSAJE_SELECCIONE_TIPO_RESERVA, opciones_tipo_reserva)
    when_i_send_keyboard_updates(token, MENSAJE_SELECCIONE_TIPO_RESERVA, 'm|pepe@gmail', opciones_tipo_reserva)
  end

  def cuando_pido_reservar_turno_por_especialidad(token)
    stub_request(:post, "https://api.telegram.org/bot#{token}/editMessageReplyMarkup")
      .with(
        body: hash_including({
                               'chat_id' => USER_ID.to_s,
                               'message_id' => '626'
                             })
      )
      .to_return(status: 200, body: { "ok": true }.to_json, headers: {})

    when_i_send_text(token, '/pedir-turno')
    then_i_get_keyboard_message(token, MENSAJE_SELECCIONE_TIPO_RESERVA, opciones_tipo_reserva)
    when_i_send_keyboard_updates(token, MENSAJE_SELECCIONE_TIPO_RESERVA, 'e|pepe@gmail', opciones_tipo_reserva)
  end

  it 'should get a /version message and respond with current version' do
    stub_api
    when_i_send_text('fake_token', '/version')
    then_i_get_text('fake_token', "BOT version: #{Version.current} - API version: 0.0.1")

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

  describe 'Reserva de turno' do
    it 'deberia recibir un mensaje /pedir-turno y responder con dos inline keyboard' do
      stub_registrado(true)

      when_i_send_text('fake_token', '/pedir-turno')
      then_i_get_keyboard_message('fake_token', MENSAJE_SELECCIONE_TIPO_RESERVA, opciones_tipo_reserva)

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

      cuando_pido_reservar_turno_por_medico('fake_token')
      then_i_get_text('fake_token', MENSAJE_ERROR_MEDICOS)

      run_bot_once('fake_token')
    end

    it 'deberia recibir un mensaje "Seleccione un médico" y responder con un inline keyboard' do
      token = 'fake_token'
      setup_y_espera_inline_keyboard_turnos(token, MENSAJE_SELECCIONE_MEDICO, '123|Clinica|pepe@gmail', opciones_medicos, opciones_turnos)
      run_bot_once(token)
    end

    it 'deberia recibir un mensaje "Seleccione una especialidad" y responder con un inline keyboard' do
      token = 'fake_token'
      setup_y_espera_inline_keyboard_medicos_por_especialidad(token, MENSAJE_SELECCIONE_ESPECIALIDAD, 'Clinica|pepe@gmail', opciones_especialidades, opciones_medicos)
      run_bot_once(token)
    end

    it 'muestra un mensaje de error si la API de turnos falla' do
      token = 'fake_token'
      setup_turnos_fallidos(token, MENSAJE_SELECCIONE_MEDICO, '123|Clinica|pepe@gmail', opciones_medicos)
      then_i_get_text(token, MENSAJE_ERROR_TURNOS)
      run_bot_once(token)
    end

    it 'deberia recibir un mensaje Seleccione un turno y responder con un mensaje de confirmación' do
      token = 'fake_token'
      setup_turno_confirmacion(token)
      when_i_send_keyboard_updates(token, MENSAJE_SELECCIONE_TURNO, '2023-10-01|10:00|123|Clinica|pepe@gmail', opciones_turnos)
      then_i_get_text(token, format(MENSAJE_TURNO_CONFIRMADO, fecha: '2023-10-01', hora: '10:00', medico: 'Carlos Sanchez', especialidad: 'Clinica'))
      run_bot_once(token)
    end

    it 'muestra un mensaje de error si la API de reservar turno falla' do
      token = 'fake_token'
      setup_reserva_turno_fallida(token)
      when_i_send_keyboard_updates(token, MENSAJE_SELECCIONE_TURNO, '2023-10-01|10:00|123|Clinica|pepe@gmail', opciones_turnos)
      then_i_get_text(token, MENSAJE_ERROR_RESERVA)
      run_bot_once(token)
    end

    it 'muestra un mensaje de error si se quiere reservar un turno ya reservado' do
      token = 'fake_token'
      setup_turno_ya_reservado(token)
      when_i_send_keyboard_updates(token, MENSAJE_SELECCIONE_TURNO, '2023-10-01|10:00|123|Clinica|pepe@gmail', opciones_turnos)
      then_i_get_text(token, MENSAJE_ERROR_TURNO_EXISTENTE)
      run_bot_once(token)
    end

    it 'muestra un mensaje de error si esta penalizado al reservar un turno' do
      token = 'fake_token'
      setup_reserva_turno_penalizado(token)
      when_i_send_keyboard_updates(token, MENSAJE_SELECCIONE_TURNO, '2023-10-01|10:00|123|Clinica|pepe@gmail', opciones_turnos)
      then_i_get_text(token, MENSAJE_PENALIZACION)
      run_bot_once(token)
    end

    it 'deberia recibir un mensaje "Seleccione un médico" y responder con que no hay médicos disponibles' do
      stub_registrado(true)
      stub_medicos_disponibles_exitoso([])

      cuando_pido_reservar_turno_por_medico('fake_token')
      then_i_get_text('fake_token', MENSAJE_NO_MEDICOS)

      run_bot_once('fake_token')
    end

    it 'deberia recibir un mensaje "Seleccione el tipo de reserva" y responder con que no hay especialidades disponibles' do
      stub_registrado(true)
      stub_especialidades_disponibles_exitoso([])

      cuando_pido_reservar_turno_por_especialidad('fake_token')
      then_i_get_text('fake_token', MENSAJE_NO_ESPECIALIDADES)

      run_bot_once('fake_token')
    end

    it 'deberia recibir un mensaje "Seleccione un médico" y responder con un mensaje con que no hay turnos disponibles' do
      token = 'fake_token'
      setup_sin_turnos_disponibles(token, MENSAJE_SELECCIONE_MEDICO, '123|Clinica|pepe@gmail', opciones_medicos)
      then_i_get_text(token, MENSAJE_NO_TURNOS)
      run_bot_once(token)
    end

    it 'deberia recibir un mensaje "Seleccione una especialidad" y responder con un mensaje con que no hay medicos disponibles' do
      token = 'fake_token'
      setup_sin_medicos_por_especialidad_disponibles(token, MENSAJE_SELECCIONE_ESPECIALIDAD, 'Clinica|pepe@gmail', opciones_especialidades)
      then_i_get_text(token, MENSAJE_NO_MEDICOS_ESPECIALIDAD)
      run_bot_once(token)
    end
  end

  describe 'cancelacion de turno' do
    it 'deberia recibir un mensaje /cancelar-turno y responde turno con estado cancelado' do
      stub_registrado(true)
      stub_cancelar_turno_exitoso(1, 'pepe@gmail', false)
      when_i_send_text('fake_token', '/cancelar-turno 1')
      then_i_get_text('fake_token', MENSAJE_TURNO_CANCELADO)

      run_bot_once('fake_token')
    end

    it 'deberia recibir un mensaje /cancelar-turno y responde con un inline keyboard' do
      stub_registrado(true)
      stub_cancelar_turno_sin_anticipacion(1, 'pepe@gmail', false)
      when_i_send_text('fake_token', '/cancelar-turno 1')
      then_i_get_keyboard_message('fake_token', MENSAJE_CONFIRMAR_CANCELACION_TURNO, opciones_confirmacion)
      run_bot_once('fake_token')
    end

    it 'deberia recibir un mensaje inline keyboard y turno con estado ausente' do
      stub_registrado(true)

      setup_cancelacion_sin_anticipacion('fake_token', MENSAJE_CONFIRMAR_CANCELACION_TURNO, 'true|1|pepe@gmail', opciones_confirmacion)
      then_i_get_text('fake_token', MENSAJE_TURNO_AUSENTE)

      run_bot_once('fake_token')
    end
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

    cuando_pido_reservar_turno_por_medico('fake_token')
    then_i_get_text('fake_token', MENSAJE_ERROR_GENERAL)

    run_bot_once('fake_token')
  end

  it 'muestra un mensaje de error si hay un error de conexión al reservar turno' do
    token = 'fake_token'
    setup_reserva_turno_con_error_conexion(token)
    when_i_send_keyboard_updates(token, MENSAJE_SELECCIONE_TURNO, '2023-10-01|10:00|123|Clinica|pepe@gmail', opciones_turnos)
    then_i_get_text(token, MENSAJE_ERROR_GENERAL)
    run_bot_once(token)
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

  describe 'Proximos turnos de un paciente' do
    it 'muestra un listado de turnos proximos del paciente' do
      token = 'fake_token'
      stub_turnos_proximos_exitoso
      when_i_send_text(token, '/mis-turnos')
      then_i_get_text(token, "Tus próximos turnos:\nID: 1 - Carlos Sanchez - Clinica - 2023-10-01 10:00\nID: 2 - Maria Perez - Pediatria - 2023-10-02 11:00")
      BotClient.new(token).run_once
    end

    it 'muestra un mensaje de error si no hay turnos proximos' do
      token = 'fake_token'
      stub_turnos_proximos_fallido
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
  end

  describe 'Historial de turnos de un paciente' do
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

  describe 'Alertas de botones deshabilitados' do
    def opciones_turnos_con_seleccion
      [
        [{ 'text' => '[ 2023-10-01 - 10:00 ]', 'callback_data' => 'disabled' }],
        [{ 'text' => '2023-10-01 - 11:00', 'callback_data' => 'disabled' }],
        [{ 'text' => '2023-10-01 - 12:00', 'callback_data' => 'disabled' }]
      ]
    end

    def opciones_medicos_con_seleccion
      [
        [{ 'text' => '[ Carlos Sanchez ]', 'callback_data' => 'disabled' }],
        [{ 'text' => 'Maria Perez', 'callback_data' => 'disabled' }],
        [{ 'text' => 'Juan Ramirez', 'callback_data' => 'disabled' }]
      ]
    end

    def stub_edit_message_reply_markup_alert(token)
      stub_request(:post, "https://api.telegram.org/bot#{token}/editMessageReplyMarkup")
        .with(
          body: hash_including({
                                 'chat_id' => USER_ID.to_s,
                                 'message_id' => '626'
                               })
        )
        .to_return(status: 200, body: { "ok": true }.to_json, headers: {})
    end

    def stub_answer_callback_query_alert(token)
      stub_request(:post, "https://api.telegram.org/bot#{token}/answerCallbackQuery")
        .with(body: hash_including({ 'callback_query_id' => '608740940475689651' }))
        .to_return(status: 200, body: { "ok": true }.to_json, headers: {})
    end

    def setup_alerta_medico_ya_seleccionado(token, opciones_medicos_con_seleccion)
      stub_edit_message_reply_markup_alert(token)
      stub_answer_callback_query_alert(token)
      when_i_send_keyboard_updates(token, MENSAJE_SELECCIONE_MEDICO, 'disabled', opciones_medicos_con_seleccion)
    end

    it 'muestra una alerta cuando se intenta seleccionar un médico al ya haber uno seleccionado' do
      setup_alerta_medico_ya_seleccionado('fake_token', opciones_medicos_con_seleccion)
      then_i_get_callback_alert('fake_token', MENSAJE_MEDICO_YA_SELECCIONADO)
      run_bot_once('fake_token')
    end

    def setup_alerta_turno_ya_seleccionado(token, opciones_turnos_con_seleccion)
      stub_edit_message_reply_markup_alert(token)
      stub_answer_callback_query_alert(token)
      when_i_send_keyboard_updates(token, MENSAJE_SELECCIONE_TURNO, 'disabled', opciones_turnos_con_seleccion)
    end

    it 'muestra una alerta cuando se intenta seleccionar un turno al ya haber uno seleccionado' do
      setup_alerta_turno_ya_seleccionado('fake_token', opciones_turnos_con_seleccion)
      then_i_get_callback_alert('fake_token', MENSAJE_TURNO_YA_SELECCIONADO)
      run_bot_once('fake_token')
    end

    it 'muestra una alerta cuando se intenta seleccionar un médico ya seleccionado (botón disabled)' do
      stub_edit_message_reply_markup_alert('fake_token')
      stub_answer_callback_query_alert('fake_token')

      when_i_send_keyboard_updates('fake_token', MENSAJE_SELECCIONE_MEDICO, 'disabled', opciones_medicos)
      then_i_get_callback_alert('fake_token', MENSAJE_MEDICO_YA_SELECCIONADO)
      run_bot_once('fake_token')
    end

    it 'muestra una alerta cuando se intenta seleccionar un turno ya seleccionado (botón disabled)' do
      stub_edit_message_reply_markup_alert('fake_token')
      stub_answer_callback_query_alert('fake_token')

      when_i_send_keyboard_updates('fake_token', MENSAJE_SELECCIONE_TURNO, 'disabled', opciones_turnos)
      then_i_get_callback_alert('fake_token', MENSAJE_TURNO_YA_SELECCIONADO)
      run_bot_once('fake_token')
    end

    it 'muestra una alerta cuando se intenta seleccionar una especialidad ya seleccionada (botón disabled)' do
      stub_edit_message_reply_markup_alert('fake_token')
      stub_answer_callback_query_alert('fake_token')

      when_i_send_keyboard_updates('fake_token', MENSAJE_SELECCIONE_ESPECIALIDAD, 'disabled', opciones_especialidades)
      then_i_get_callback_alert('fake_token', MENSAJE_ESPECIALIDAD_YA_SELECCIONADA)
      run_bot_once('fake_token')
    end

    it 'muestra una alerta cuando se intenta seleccionar un tipo de reserva ya seleccionado (botón disabled)' do
      stub_edit_message_reply_markup_alert('fake_token')
      stub_answer_callback_query_alert('fake_token')

      when_i_send_keyboard_updates('fake_token', MENSAJE_SELECCIONE_TIPO_RESERVA, 'disabled', opciones_tipo_reserva)
      then_i_get_callback_alert('fake_token', MENSAJE_TIPO_DE_RESERVA_YA_SELECCIONADO)
      run_bot_once('fake_token')
    end
  end

  describe 'Superposicion de turnos' do
    it 'muestra un mensaje de error si se intenta reservar un turno que se superpone con otro ya reservado' do
      token = 'fake_token'
      setup_turno_superpuesto(token)
      when_i_send_keyboard_updates(token, MENSAJE_SELECCIONE_TURNO, '2023-10-01|10:00|123|Clinica|pepe@gmail', opciones_turnos)
      then_i_get_text(token, MENSAJE_ERROR_TURNO_CON_SUPERPOSICION)
      run_bot_once(token)
    end
  end
end
