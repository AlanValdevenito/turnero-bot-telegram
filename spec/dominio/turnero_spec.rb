require 'spec_helper'
require_relative '../../app/turnero/turnero'
require_relative '../../app/turnero/excepciones/limite_turnos_exception'

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
    expect(turnero.reservar_turno('12345', '2025-06-10', '10:00', email)).to eq(turno)
  end

  it 'da error si el turno ya fue tomado' do
    resultado = ResultadoReserva.new(exito: false, error: 'Ya existe un turno para ese médico y fecha/hora')
    allow(proveedor_mock).to receive(:reservar_turno).and_return(resultado)
    expect { turnero.reservar_turno('12345', 'fecha', 'hora', email) }.to raise_error(TurnoYaExisteException)
  end

  it 'da error si el medico no fue encontrado al reservar turno' do
    resultado = ResultadoReserva.new(exito: false, error: 'Médico no encontrado')
    allow(proveedor_mock).to receive(:reservar_turno).and_return(resultado)
    expect { turnero.reservar_turno('12345', 'fecha', 'hora', email) }.to raise_error(MedicoNoEncontradoException)
  end

  it 'da error si el usuario no esta registrado' do
    resultado = ResultadoRegistrado.new(exito: false)
    allow(proveedor_mock).to receive(:usuario_registrado?).and_return(resultado)
    expect { turnero.usuario_registrado?(123) }.to raise_error(UsuarioNoRegistradoException)
  end

  it 'proximos turnos exitoso' do
    turnos = [instance_double(Turno, fecha: '2025-06-10', hora: '10:00', medico: instance_double(Medico, nombre: 'Juan', apellido: 'Pérez', especialidad: 'Cardiología'))]
    resultado = ResultadoProximosTurnos.new(exito: true, turnos:)
    allow(proveedor_mock).to receive(:solicitar_proximos_turnos).and_return(resultado)
    expect(turnero.proximos_turnos_paciente(email)).to eq(turnos)
  end

  it 'da error si no hay proximos turnos' do
    resultado = ResultadoProximosTurnos.new(exito: false, error: 'El paciente no tiene próximos turnos')
    allow(proveedor_mock).to receive(:solicitar_proximos_turnos).and_return(resultado)
    expect { turnero.proximos_turnos_paciente(email) }.to raise_error(NoHayProximosTurnosException)
  end

  it 'da error si no hay turnos en el historial' do
    resultado = ResultadoHistorialTurnos.new(exito: false, error: 'El paciente no tiene turnos en su historial')
    allow(proveedor_mock).to receive(:solicitar_historial_turnos).and_return(resultado)
    expect { turnero.historial_turnos_paciente(email) }.to raise_error(NoHayTurnosEnHistorialException)
  end

  it 'historial turnos exitoso' do
    turnos = [instance_double(Turno, fecha: '2025-06-10', hora: '10:00', medico: instance_double(Medico, nombre: 'Juan', apellido: 'Pérez', especialidad: 'Cardiología'))]
    resultado = ResultadoHistorialTurnos.new(exito: true, turnos:)
    allow(proveedor_mock).to receive(:solicitar_historial_turnos).and_return(resultado)
    expect(turnero.historial_turnos_paciente(email)).to eq(turnos)
  end

  it 'deberia obtener la lista de especialidades disponibles' do
    resultado = ResultadoEspecialidadesDisponibles.new(exito: true, especialidades: [Especialidad.new.con_nombre('Traumatologia')])
    allow(proveedor_mock).to receive(:solicitar_especialidades_disponibles).and_return(resultado)
    expect(turnero.solicitar_especialidades_disponibles.first.nombre).to eq(resultado.especialidades.first.nombre)
  end

  it 'deberia devolver error si no hay especialidades disponibles' do
    resultado = ResultadoEspecialidadesDisponibles.new(exito: true, especialidades: [])
    allow(proveedor_mock).to receive(:solicitar_especialidades_disponibles).and_return(resultado)
    expect { turnero.solicitar_especialidades_disponibles }.to raise_error(NoHayEspecialidadesDisponiblesException)
  end

  it 'deberia obtener la lista de medicos por especialidad disponibles' do
    resultado = ResultadoMedicosDisponibles.new(exito: true, medicos: [Medico.new.con_nombre('Juan').con_apellido('Perez').con_matricula('ABC123').con_especialidad('Traumatologia')])
    allow(proveedor_mock).to receive(:solicitar_medicos_por_especialidad_disponibles).and_return(resultado)
    medicos = turnero.solicitar_medicos_por_especialidad_disponibles('Traumatologia')
    expect(medicos.first.matricula).to eq(resultado.medicos.first.matricula)
  end

  it 'deberia devolver error si no hay medicos por especialidad disponibles' do
    resultado = ResultadoMedicosDisponibles.new(exito: false, error: 'Especialidad sin medicos dados de alta')
    allow(proveedor_mock).to receive(:solicitar_medicos_por_especialidad_disponibles).and_return(resultado)
    expect { turnero.solicitar_medicos_por_especialidad_disponibles('Traumatologia') }.to raise_error(NoHayMedicosDisponiblesException)
  end

  it 'deberia devolver error si se intenta cancelar un turno con menos de 24hs de anticipacion' do
    resultado = ResultadoCancelarTurno.new(exito: false, error: 'Necesitas confirmacion para cancelar este turno')
    allow(proveedor_mock).to receive(:cancelar_turno).and_return(resultado)
    expect { turnero.cancelar_turno(1, 'pepe@mail.com', false) }.to raise_error(CancelacionNecesitaConfirmacionException)
  end

  it 'deberia devolver error si se intenta cancelar un turno que no existe o no te pertenece' do
    resultado = ResultadoCancelarTurno.new(exito: false, error: 'No puedes cancelar este turno')
    allow(proveedor_mock).to receive(:cancelar_turno).and_return(resultado)
    expect { turnero.cancelar_turno(1, 'pepe@mail.com', false) }.to raise_error(NoPodesCancelarTurnoInexistenteException)
  end

  it 'deberia devolver error si se intenta reservar un turno que se superpone con otro ya reservado' do
    resultado = ResultadoReserva.new(exito: false, error: 'Ya existe un turno reservado en esa fecha y horario')
    allow(proveedor_mock).to receive(:reservar_turno).and_return(resultado)
    expect { turnero.reservar_turno('12345', '2025-06-10', '10:00', email) }.to raise_error(SuperposicionDeTurnosException)
  end

  it 'deberia devolver error si se supera el limite de turnos para una especialidad' do
    resultado = ResultadoReserva.new(exito: false, error: 'El usuario ha alcanzado el límite de turnos para esta especialidad')
    allow(proveedor_mock).to receive(:reservar_turno).and_return(resultado)
    expect { turnero.reservar_turno('12345', '2025-06-10', '10:00', email) }.to raise_error(LimiteDeTurnosException)
  end

  it 'deberia lanzar excepcion si el usuario esta penalizado' do
    resultado = ResultadoPenalizacion.new(exito: false, error: 'El usuario está penalizado')
    allow(proveedor_mock).to receive(:penalizar_si_corresponde).and_return(resultado)
    expect { turnero.penalizar_si_corresponde(email) }.to raise_error(PenalizacionPorReputacionException)
  end
end
