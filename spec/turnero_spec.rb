require 'spec_helper'
require_relative '../app/turnero/turnero'

describe 'Turnero' do
  let(:proveedor_mock) { instance_double('ProveedorTurnero') }
  let(:turnero) { Turnero.new(proveedor_mock) }
  let(:email) { 'paciente@ejemplo.com' }
  let(:telegram_id) { 1234 }

  it 'registracion exitosa' do
    resultado = ResultadoCrearUsuario.new(exito: true)
    allow(proveedor_mock).to receive(:crear_usuario).with(email, telegram_id).and_return(resultado)
    expect { turnero.registrar_paciente(email, telegram_id) }.not_to raise_error
  end

  it 'da error si el email ya esta en uso' do
    resultado = ResultadoCrearUsuario.new(exito: false, error: 'El email ingresado ya está en uso')
    allow(proveedor_mock).to receive(:crear_usuario).and_return(resultado)
    expect { turnero.registrar_paciente(email, telegram_id) }.to raise_error(EmailYaEnUsoException)
  end

  it 'da error si el paciente ya esta registrado' do
    resultado = ResultadoCrearUsuario.new(exito: false, error: 'El paciente ya está registrado')
    allow(proveedor_mock).to receive(:crear_usuario).and_return(resultado)
    expect { turnero.registrar_paciente(email, telegram_id) }.to raise_error(PacienteYaRegistradoException)
  end

  it 'da error si no hay medicos disponibles' do
    resultado = ResultadoMedicosDisponibles.new(exito: true, medicos: [])
    allow(proveedor_mock).to receive(:solicitar_medicos_disponibles).and_return(resultado)
    expect { turnero.solicitar_medicos_disponibles }.to raise_error(NoHayMedicosDisponiblesException)
  end

  it 'da error si no hay turnos disponibles' do
    resultado = ResultadoTurnosDisponibles.new(exito: false, error: 'No hay turnos disponibles')
    allow(proveedor_mock).to receive(:solicitar_turnos_disponibles).and_return(resultado)
    expect { turnero.solicitar_turnos_disponibles('12345', 'Cardiologia') }.to raise_error(NohayTurnosDisponiblesException)
  end

  it 'reserva exitosa' do
    medico = instance_double(Medico, nombre: 'Juan', apellido: 'Pérez', matricula: '12345', especialidad: 'Cardiología')
    turno = instance_double(Turno, fecha: '2025-06-10', hora: '10:00', medico:)
    resultado = ResultadoReserva.new(exito: true, turno:)
    allow(proveedor_mock).to receive(:reservar_turno).and_return(resultado)
    expect(turnero.reservar_turno('12345', '2025-06-10', '10:00', telegram_id)).to eq(turno)
  end

  it 'da error si el turno ya fue tomado' do
    resultado = ResultadoReserva.new(exito: false, error: 'Ya existe un turno para ese médico y fecha/hora')
    allow(proveedor_mock).to receive(:reservar_turno).and_return(resultado)
    expect { turnero.reservar_turno('12345', 'fecha', 'hora', 'Cardiologia') }.to raise_error(TurnoYaExisteException)
  end

  it 'da error si el medico no fue encontrado al reservar turno' do
    resultado = ResultadoReserva.new(exito: false, error: 'Médico no encontrado')
    allow(proveedor_mock).to receive(:reservar_turno).and_return(resultado)
    expect { turnero.reservar_turno('12345', 'fecha', 'hora', 'Cardiologia') }.to raise_error(MedicoNoEncontradoException)
  end

  it 'da error si el usuario no esta registrado' do
    allow(proveedor_mock).to receive(:usuario_registrado?).and_return(false)
    expect { turnero.usuario_registrado?(123) }.to raise_error(UsuarioNoRegistradoException)
  end

  it 'proximos turnos exitoso' do
    turnos = [instance_double(Turno, fecha: '2025-06-10', hora: '10:00', medico: instance_double(Medico, nombre: 'Juan', apellido: 'Pérez', especialidad: 'Cardiología'))]
    resultado = ResultadoProximosTurnos.new(exito: true, turnos:)
    allow(proveedor_mock).to receive(:solicitar_proximos_turnos).and_return(resultado)
    expect(turnero.proximos_turnos_paciente(telegram_id)).to eq(turnos)
  end

  it 'da error si no hay proximos turnos' do
    resultado = ResultadoProximosTurnos.new(exito: false, error: 'El paciente no tiene próximos turnos')
    allow(proveedor_mock).to receive(:solicitar_proximos_turnos).and_return(resultado)
    expect { turnero.proximos_turnos_paciente(telegram_id) }.to raise_error(NoHayProximosTurnosException)
  end

  it 'da error si no hay turnos en el historial' do
    resultado = ResultadoHistorialTurnos.new(exito: false, error: 'El paciente no tiene turnos en su historial')
    allow(proveedor_mock).to receive(:solicitar_historial_turnos).and_return(resultado)
    expect { turnero.historial_turnos_paciente(telegram_id) }.to raise_error(NoHayTurnosEnHistorialException)
  end
end
