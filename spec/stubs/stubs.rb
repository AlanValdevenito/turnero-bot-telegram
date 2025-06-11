require 'webmock/rspec'

def stub_api
  api_response_body = { "version": '0.0.1' }
  stub_request(:get, "#{ENV['API_URL']}/version")
    .to_return(status: 200, body: api_response_body.to_json, headers: {})
end

def stub_registro(email, telegram_id)
  stub_request(:post, "#{ENV['API_URL']}/usuarios")
    .with(
      body: { email:, telegram_id: }.to_json,
      headers: { 'Content-Type' => 'application/json' }
    ).to_return(status: 200, body: { id: 123, email: }.to_json)
end

def stub_email_en_uso(email, telegram_id)
  stub_request(:post, "#{ENV['API_URL']}/usuarios")
    .with(
      body: { email:, telegram_id: }.to_json,
      headers: { 'Content-Type' => 'application/json' }
    ).to_return(status: 400, body: { error: 'El email ingresado ya está en uso' }.to_json)
end

def stub_paciente_ya_registrado(email, telegram_id)
  stub_request(:post, "#{ENV['API_URL']}/usuarios")
    .with(
      body: { email:, telegram_id: }.to_json,
      headers: { 'Content-Type' => 'application/json' }
    ).to_return(status: 400, body: { error: 'El paciente ya se encuentra registrado' }.to_json)
end

def stub_medicos_disponibles_exitoso(medicos)
  stub_request(:get, "#{ENV['API_URL']}/turnos/medicos-disponibles")
    .to_return(status: 200, body: medicos.to_json, headers: { 'Content-Type' => 'application/json' })
end

def stub_medicos_disponibles_fallido
  stub_request(:get, "#{ENV['API_URL']}/turnos/medicos-disponibles")
    .to_return(status: 500, body: { error: 'Error interno' }.to_json, headers: { 'Content-Type' => 'application/json' })
end

def stub_turnos_disponibles_exitoso(turnos, matricula = '123')
  stub_request(:get, "#{ENV['API_URL']}/turnos/#{matricula}/disponibilidad")
    .to_return(status: 200, body: turnos.to_json, headers: { 'Content-Type' => 'application/json' })
end

def stub_turnos_disponibles_fallido_vacio(matricula = '123')
  stub_request(:get, "#{ENV['API_URL']}/turnos/#{matricula}/disponibilidad")
    .to_return(status: 400, body: { error: 'No hay turnos disponibles' }.to_json, headers: { 'Content-Type' => 'application/json' })
end

def stub_turnos_disponibles_fallido(matricula = '123')
  stub_request(:get, "#{ENV['API_URL']}/turnos/#{matricula}/disponibilidad")
    .to_return(status: 500, body: { error: 'Error interno' }.to_json, headers: { 'Content-Type' => 'application/json' })
end

def stub_reservar_turno_exitoso
  stub_request(:post, "#{ENV['API_URL']}/turnos")
    .with(
      body: { matricula: '123', fecha: '2023-10-01', hora: '10:00', telegram_id: USER_ID.to_s }.to_json,
      headers: { 'Content-Type' => 'application/json' }
    )
    .to_return(status: 200, body: {
      message: 'El turno se reservó exitosamente',
      id: 1,
      fecha: '2023-10-01',
      hora: '10:00',
      medico: { nombre: 'Carlos', apellido: 'Sanchez', matricula: '123', especialidad: 'Clinica' }
    }.to_json, headers: { 'Content-Type' => 'application/json' })
end

def stub_reservar_turno_fallido
  stub_request(:post, "#{ENV['API_URL']}/turnos")
    .with(
      body: { matricula: '123', fecha: '2023-10-01', hora: '10:00', telegram_id: USER_ID.to_s }.to_json,
      headers: { 'Content-Type' => 'application/json' }
    )
    .to_return(status: 500, body: { error: 'Error interno' }.to_json, headers: { 'Content-Type' => 'application/json' })
end

def stub_reservar_turno_ya_reservado
  stub_request(:post, "#{ENV['API_URL']}/turnos")
    .with(
      body: { matricula: '123', fecha: '2023-10-01', hora: '10:00', telegram_id: USER_ID.to_s }.to_json,
      headers: { 'Content-Type' => 'application/json' }
    )
    .to_return(status: 400, body: { error: 'Ya existe un turno para ese médico y fecha/hora' }.to_json, headers: { 'Content-Type' => 'application/json' })
end

def stub_flujo_turno_ya_reservado(turnos_disponibles, matricula = '123')
  stub_registrado(true)
  stub_turnos_disponibles_exitoso(turnos_disponibles, matricula)
  stub_reservar_turno_ya_reservado
end

def stub_registrado(exito)
  if exito
    stub_request(:get, "#{ENV['API_URL']}/usuarios/telegram/#{USER_ID}")
      .to_return(status: 200, body: { id: 123, email: 'paciente@example.com', telegram_id: USER_ID }.to_json, headers: { 'Content-Type' => 'application/json' })
  else
    stub_request(:get, "#{ENV['API_URL']}/usuarios/telegram/#{USER_ID}")
      .to_return(status: 404, body: { error: 'Usuario no encontrado' }.to_json, headers: { 'Content-Type' => 'application/json' })
  end
end

def stub_error_conexion(tipo, ruta)
  stub_request(tipo, "#{ENV['API_URL']}#{ruta}")
    .to_raise(Faraday::ConnectionFailed.new('Error de conexión'))
end

def stub_flujo_reserva_turno_con_error_conexion(medicos_disponibles, turnos_disponibles, matricula = '123')
  stub_registrado(true)
  stub_medicos_disponibles_exitoso(medicos_disponibles)
  stub_turnos_disponibles_exitoso(turnos_disponibles, matricula)
  stub_error_conexion(:post, '/turnos')
end

def stub_flujo_turnos_disponibles_con_error_conexion(medicos_disponibles, matricula = '123')
  stub_registrado(true)
  stub_medicos_disponibles_exitoso(medicos_disponibles)
  stub_error_conexion(:get, "/turnos/#{matricula}/disponibilidad")
end

def stub_error_interno_api(tipo, ruta)
  stub_request(tipo, "#{ENV['API_URL']}#{ruta}")
    .to_return(status: 500, body: { error: 'Error interno' }.to_json, headers: { 'Content-Type' => 'application/json' })
end

def stub_turnos_proximos_exitoso
  stub_registrado(true)
  stub_request(:get, "#{ENV['API_URL']}/turnos/pacientes/telegram/#{USER_ID}/proximos")
    .to_return(
      status: 200,
      body: [
        {
          "id": 1,
          "fecha y hora": '2023-10-01 10:00',
          "especialidad": 'Clinica',
          "medico": 'Carlos Sanchez'
        },
        {
          "id": 2,
          "fecha y hora": '2023-10-02 11:00',
          "especialidad": 'Pediatria',
          "medico": 'Maria Perez'
        }
      ].to_json,
      headers: { 'Content-Type' => 'application/json' }
    )
end

def stub_turnos_proximos_fallido
  stub_registrado(true)
  stub_request(:get, "#{ENV['API_URL']}/turnos/pacientes/telegram/#{USER_ID}/proximos")
    .to_return(
      status: 404,
      body: { error: 'No se encontraron turnos próximos' }.to_json,
      headers: { 'Content-Type' => 'application/json' }
    )
end
