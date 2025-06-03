require 'spec_helper'
require 'web_mock'
# Uncomment to use VCR
# require 'vcr_helper'

require "#{File.dirname(__FILE__)}/../app/bot_client"

ENV['API_URL'] ||= 'http://web:3000'
USER_ID = 141_733_544

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

def when_i_send_keyboard_updates(token, message_text, inline_selection)
  body = {
    "ok": true, "result": [{
      "update_id": 866_033_907,
      "callback_query": { "id": '608740940475689651', "from": { "id": USER_ID, "is_bot": false, "first_name": 'Emilio', "last_name": 'Gutter', "username": 'egutter', "language_code": 'en' },
                          "message": {
                            "message_id": 626,
                            "from": { "id": 715_612_264, "is_bot": true, "first_name": 'fiuba-memo2-prueba', "username": 'fiuba_memo2_bot' },
                            "chat": { "id": USER_ID, "first_name": 'Emilio', "last_name": 'Gutter', "username": 'egutter', "type": 'private' },
                            "date": 1_595_282_006,
                            "text": message_text,
                            "reply_markup": {
                              "inline_keyboard": [
                                [{ "text": 'Jon Snow', "callback_data": '1' }],
                                [{ "text": 'Daenerys Targaryen', "callback_data": '2' }],
                                [{ "text": 'Ned Stark', "callback_data": '3' }]
                              ]
                            }
                          },
                          "chat_instance": '2671782303129352872',
                          "data": inline_selection }
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

def then_i_get_keyboard_message(token, message_text)
  body = { "ok": true,
           "result": { "message_id": 12,
                       "from": { "id": 715_612_264, "is_bot": true, "first_name": 'fiuba-memo2-prueba', "username": 'fiuba_memo2_bot' },
                       "chat": { "id": USER_ID, "first_name": 'Emilio', "last_name": 'Gutter', "username": 'egutter', "type": 'private' },
                       "date": 1_557_782_999, "text": message_text } }

  stub_request(:post, "https://api.telegram.org/bot#{token}/sendMessage")
    .with(
      body: { 'chat_id' => '141733544',
              'reply_markup' => '{"inline_keyboard":[[{"text":"Jon Snow","callback_data":"1"},{"text":"Daenerys Targaryen","callback_data":"2"},{"text":"Ned Stark","callback_data":"3"}]]}',
              'text' => 'Quien se queda con el trono?' }
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
  stub_request(:post, "#{ENV['API_URL']}/registrar")
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
  stub_request(:post, "#{ENV['API_URL']}/registrar")
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
  stub_request(:post, "#{ENV['API_URL']}/registrar")
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

describe 'BotClient' do
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

    app = BotClient.new(token)

    app.run_once
  end

  it 'should get a /start message and respond with Hola' do
    token = 'fake_token'

    when_i_send_text(token, '/start')
    then_i_get_text(token, 'Hola, Emilio')

    app = BotClient.new(token)

    app.run_once
  end

  it 'should get a /stop message and respond with Chau' do
    token = 'fake_token'

    when_i_send_text(token, '/stop')
    then_i_get_text(token, 'Chau, egutter')

    app = BotClient.new(token)

    app.run_once
  end

  it 'should get a /tv message and respond with an inline keyboard' do
    token = 'fake_token'

    when_i_send_text(token, '/tv')
    then_i_get_keyboard_message(token, 'Quien se queda con el trono?')

    app = BotClient.new(token)

    app.run_once
  end

  it 'should get a "Quien se queda con el trono?" message and respond with' do
    token = 'fake_token'

    when_i_send_keyboard_updates(token, 'Quien se queda con el trono?', '2')
    then_i_get_text(token, 'A mi también me encantan los dragones!')

    app = BotClient.new(token)

    app.run_once
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
