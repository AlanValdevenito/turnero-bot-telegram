require 'spec_helper'
require 'web_mock'
require_relative '../app/turnero/proveedor_turnero'

describe 'ProveedorTurnero' do
  let(:api_url) { 'http://web:3000' }
  let(:turnero) { ProveedorTurnero.new(api_url) }
  let(:email) { 'test@test.com' }
  let(:telegram_id) { 1234 }
  let(:medicos_disponibles) do
    [
      { 'nombre' => 'Carlos', 'apellido' => 'Sanchez', 'matricula' => '123', 'especialidad' => 'Clínica' },
      { 'nombre' => 'Maria', 'apellido' => 'Perez', 'matricula' => '456', 'especialidad' => 'Pediatría' }
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

  it 'registra un usuario exitosamente' do
    response_body = { message: 'El paciente se registró existosamente' }.to_json

    cuando_quiero_registrar_usuario(email, telegram_id)
    response = turnero.crear_usuario(email, telegram_id)

    expect(response).to eq(JSON.parse(response_body))
  end

  it 'da error cuando el email ya está en uso' do
    cuando_quiero_registrar_usuario_email_en_uso(email, telegram_id)

    expect { turnero.crear_usuario(email, telegram_id) }.to raise_error(EmailYaEnUsoException)
  end

  it 'da error cuando el paciente ya está registrado' do
    cuando_quiero_registrar_paciente_ya_registrado(email, telegram_id)

    expect { turnero.crear_usuario(email, telegram_id) }.to raise_error(PacienteYaRegistradoException)
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
end
