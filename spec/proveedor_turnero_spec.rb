require 'spec_helper'
require 'web_mock'
require_relative '../app/turnero/proveedor_turnero'

describe 'ProveedorTurnero' do
  let(:datos_usuario) { { email: 'test@test.com', telegram_id: 1234 } }
  let(:api_url) { 'http://web:3000' }
  let(:turnero) { ProveedorTurnero.new(api_url) }
  let(:medicos_disponibles) do
    [
      { 'nombre' => 'Carlos', 'apellido' => 'Sanchez', 'matricula' => '123', 'especialidad' => 'Clínica' },
      { 'nombre' => 'Maria', 'apellido' => 'Perez', 'matricula' => '456', 'especialidad' => 'Pediatría' }
    ]
  end
  let(:turnos_disponibles) do
    [
      { 'fecha' => '2024-06-05', 'hora' => '10:00', 'medico_id' => '123' },
      { 'fecha' => '2024-06-05', 'hora' => '11:00', 'medico_id' => '123' }
    ]
  end

  def cuando_quiero_registrar_usuario(email, telegram_id)
    stub_request(:post, "#{api_url}/usuarios")
      .with(body: { email:, telegram_id: })
      .to_return(status: 200, body: { message: 'El paciente se registró existosamente' }.to_json, headers: { 'Content-Type' => 'application/json' })
  end

  def cuando_quiero_registrar_usuario_email_en_uso(email, telegram_id)
    stub_request(:post, "#{api_url}/usuarios")
      .with(body: { email:, telegram_id: })
      .to_return(status: 400, body: { error: 'El email ingresado ya está en uso' }.to_json, headers: { 'Content-Type' => 'application/json' })
  end

  def cuando_quiero_registrar_paciente_ya_registrado(email, telegram_id)
    stub_request(:post, "#{api_url}/usuarios")
      .with(body: { email:, telegram_id: })
      .to_return(status: 400, body: { error: 'El paciente ya está registrado' }.to_json, headers: { 'Content-Type' => 'application/json' })
  end

  def crear_turno_exitoso(matricula, fecha, hora, telegram_id)
    stub_request(:post, "#{api_url}/turnos")
      .with(body: { matricula:, fecha:, hora:, telegram_id: })
      .to_return(status: 200, body: { message: 'Turno reservado exitosamente' }.to_json, headers: { 'Content-Type' => 'application/json' })
  end

  it 'registra un usuario exitosamente' do
    response_body = { message: 'El paciente se registró existosamente' }.to_json

    cuando_quiero_registrar_usuario(datos_usuario[:email], datos_usuario[:telegram_id])
    response = turnero.crear_usuario(datos_usuario[:email], datos_usuario[:telegram_id])

    expect(response).to eq(JSON.parse(response_body))
  end

  it 'da error cuando el email ya está en uso' do
    cuando_quiero_registrar_usuario_email_en_uso(datos_usuario[:email], datos_usuario[:telegram_id])

    expect { turnero.crear_usuario(datos_usuario[:email], datos_usuario[:telegram_id]) }.to raise_error(EmailYaEnUsoException)
  end

  it 'da error cuando el paciente ya está registrado' do
    cuando_quiero_registrar_paciente_ya_registrado(datos_usuario[:email], datos_usuario[:telegram_id])

    expect { turnero.crear_usuario(datos_usuario[:email], datos_usuario[:telegram_id]) }.to raise_error(PacienteYaRegistradoException)
  end

  it 'obtiene la lista de médicos disponibles con todos los campos' do
    stub_request(:get, "#{api_url}/turnos/medicos-disponibles")
      .to_return(status: 200, body: medicos_disponibles.to_json, headers: { 'Content-Type' => 'application/json' })

    response = turnero.solicitar_medicos_disponibles

    expect(response).to eq(medicos_disponibles)
  end

  it 'maneja errores al solicitar médicos disponibles' do
    stub_request(:get, "#{api_url}/turnos/medicos-disponibles")
      .to_return(status: 500, body: { error: 'Error interno del servidor' }.to_json, headers: { 'Content-Type' => 'application/json' })

    expect { turnero.solicitar_medicos_disponibles }.to raise_error(ErrorAPIMedicosDisponiblesException)
  end

  it 'maneja errores de conexión al solicitar médicos disponibles' do
    stub_request(:get, "#{api_url}/turnos/medicos-disponibles")
      .to_raise(Faraday::Error.new('Error de conexión'))

    expect { turnero.solicitar_medicos_disponibles }.to raise_error(ErrorAPIMedicosDisponiblesException)
  end

  it 'obtiene la disponibilidad de turnos para un médico' do
    matricula = '123'

    stub_request(:get, "#{api_url}/turnos/#{matricula}/disponibilidad")
      .to_return(status: 200, body: turnos_disponibles.to_json, headers: { 'Content-Type' => 'application/json' })

    response = turnero.solicitar_turnos_disponibles(matricula, 'fake_especialidad')
    expect(response).to eq(turnos_disponibles)
  end

  it 'maneja errores al solicitar turnos disponibles' do
    matricula = '999'
    stub_request(:get, "#{api_url}/turnos/#{matricula}/disponibilidad")
      .to_return(status: 404, body: { error: 'Médico no encontrado' }.to_json, headers: { 'Content-Type' => 'application/json' })

    expect { turnero.solicitar_turnos_disponibles(matricula, 'fake_especialidad') }.to raise_error(ErrorAPITurnosDisponiblesException)
  end

  it 'maneja errores de conexión al solicitar turnos disponibles' do
    matricula = '999'
    stub_request(:get, "#{api_url}/turnos/#{matricula}/disponibilidad")
      .to_raise(Faraday::Error.new('Error de conexión'))

    expect { turnero.solicitar_turnos_disponibles(matricula, 'fake_especialidad') }.to raise_error(ErrorAPITurnosDisponiblesException)
  end

  it 'reserva un turno exitosamente' do
    crear_turno_exitoso('123', '2024-06-05', '10:00', 1234)
    response_body = { message: 'Turno reservado exitosamente' }.to_json
    response = turnero.reservar_turno('123', '2024-06-05', '10:00', 1234)

    expect(response).to eq(JSON.parse(response_body))
  end

  it 'maneja errores al reservar un turno' do
    stub_request(:post, "#{api_url}/turnos")
      .with(body: { matricula: '123', fecha: '2024-06-05', hora: '10:00', telegram_id: 1234 })
      .to_return(status: 404, body: { error: 'Error al reservar el turno' }.to_json, headers: { 'Content-Type' => 'application/json' })

    expect { turnero.reservar_turno('123', '2024-06-05', '10:00', 1234) }.to raise_error(ErrorAPIReservarTurnoException)
  end

  it 'maneja errores de conexión al reservar un turno' do
    stub_request(:post, "#{api_url}/turnos")
      .with(body: { matricula: '123', fecha: '2024-06-05', hora: '10:00', telegram_id: 1234 })
      .to_raise(Faraday::Error.new('Error de conexión'))

    expect { turnero.reservar_turno('123', '2024-06-05', '10:00', 1234) }.to raise_error(ErrorAPIReservarTurnoException)
  end

  it 'verifica si un usuario está registrado' do
    telegram_id = datos_usuario[:telegram_id]

    # Stub para usuario registrado
    stub_request(:get, "#{api_url}/usuarios/telegram/#{telegram_id}")
      .to_return(status: 200, body: { id: 1, email: datos_usuario[:email], telegram_id: }.to_json, headers: { 'Content-Type' => 'application/json' })

    expect(turnero.usuario_registrado?(telegram_id)).to be true
  end

  it 'verifica si un usuario no está registrado' do
    telegram_id = datos_usuario[:telegram_id]

    # Stub para usuario no registrado
    stub_request(:get, "#{api_url}/usuarios/telegram/#{telegram_id}")
      .to_return(status: 404, body: { error: 'Usuario no encontrado' }.to_json, headers: { 'Content-Type' => 'application/json' })

    expect(turnero.usuario_registrado?(telegram_id)).to be false
  end
end
