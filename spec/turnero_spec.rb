require 'spec_helper'
require_relative '../app/turnero/turnero'

describe 'Turnero' do
  let(:proveedor_mock) { instance_double('ProveedorTurnero') }
  let(:turnero) { Turnero.new(proveedor_mock) }
  let(:email) { 'paciente@ejemplo.com' }

  it 'registracion exitosa' do
    expect(proveedor_mock).to receive(:crear_usuario).with(email)
    turnero.registrar_paciente(email)
  end
end
