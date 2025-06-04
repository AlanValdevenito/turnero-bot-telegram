require 'spec_helper'
require_relative '../app/turnero/turnero'

describe 'Turnero' do
  let(:proveedor_mock) { instance_double('ProveedorTurnero') }
  let(:turnero) { Turnero.new(proveedor_mock) }
  let(:email) { 'paciente@ejemplo.com' }
  let(:telegram_id) { 1234 }

  it 'registracion exitosa' do
    expect(proveedor_mock).to receive(:crear_usuario).with(email, telegram_id)
    turnero.registrar_paciente(email, telegram_id)
  end

  it 'da error si el email ya esta en uso' do
    allow(proveedor_mock).to receive(:crear_usuario).and_raise(EmailYaEnUsoException)
    expect { turnero.registrar_paciente(email, telegram_id) }.to raise_error(EmailYaEnUsoException)
  end

  it 'da error si el paciente ya esta registrado' do
    allow(proveedor_mock).to receive(:crear_usuario).and_raise(PacienteYaRegistradoException)
    expect { turnero.registrar_paciente(email, telegram_id) }.to raise_error(PacienteYaRegistradoException)
  end

  it 'da error si no hay medicos disponibles' do
    allow(proveedor_mock).to receive(:solicitar_medicos_disponibles).and_return(nil)
    expect { turnero.solicitar_medicos_disponibles }.to raise_error(NoHayMedicosDisponiblesException)
  end
end
