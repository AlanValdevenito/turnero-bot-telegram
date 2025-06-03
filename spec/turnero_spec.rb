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

  it 'da error si el email ya esta en uso' do
    allow(proveedor_mock).to receive(:crear_usuario).and_raise(EmailYaEnUsoException)
    expect { turnero.registrar_paciente(email) }.to raise_error(EmailYaEnUsoException)
  end
end
