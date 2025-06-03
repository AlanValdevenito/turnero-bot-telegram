require 'spec_helper'
require 'web_mock'
require_relative '../app/turnero/proveedor_turnero'

describe 'ProveedorTurnero' do
  let(:api_url) { 'http://web:3000' }
  let(:turnero) { ProveedorTurnero.new(api_url) }

  def cuando_quiero_registrar_usuario(email)
    stub_request(:post, "#{api_url}/registrar")
      .with(body: { email: })
      .to_return(status: 200, body: { message: 'El paciente se registró existosamente' }.to_json, headers: { 'Content-Type' => 'application/json' })
  end

  it 'registra un usuario exitosamente' do
    email = 'test@test.com'

    response_body = { message: 'El paciente se registró existosamente' }.to_json

    cuando_quiero_registrar_usuario(email)
    response = turnero.crear_usuario(email)

    expect(response).to eq(JSON.parse(response_body))
  end
end
