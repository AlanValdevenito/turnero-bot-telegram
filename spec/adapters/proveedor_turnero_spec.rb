require 'spec_helper'
require 'webmock/rspec'
require_relative '../../app/turnero/proveedor_turnero/proveedor_turnero'

describe ProveedorTurnero do
  let(:contexto) do
    {
      api_url: ENV['API_URL'] || 'http://fake-api',
      api_key: ENV['API_KEY'] || 'fake-key',
      telegram_id: 1234,
      email: 'test@test.com',
      matricula: '123',
      especialidad: 'Clinica',
      fecha: '2023-10-01',
      hora: '10:00',
      turno_id: 1
    }
  end

  let(:proveedor) { described_class.new(contexto[:api_url], contexto[:api_key]) }

  describe '#usuario_registrado?' do
    it 'delega al proveedor de usuarios' do
      allow_any_instance_of(ProveedorUsuarios).to receive(:usuario_registrado?).with(contexto[:telegram_id]).and_return(instance_double('ResultadoRegistrado', exito?: true))

      resultado = proveedor.usuario_registrado?(contexto[:telegram_id])

      expect(resultado.exito?).to be true
    end
  end

  describe '#crear_usuario' do
    it 'delega al proveedor de usuarios' do
      allow_any_instance_of(ProveedorUsuarios).to receive(:crear_usuario).with(contexto[:email], contexto[:telegram_id]).and_return(instance_double('ResultadoCrearUsuario', exito?: true))

      resultado = proveedor.crear_usuario(contexto[:email], contexto[:telegram_id])

      expect(resultado.exito?).to be true
    end
  end

  describe '#penalizar_si_corresponde' do
    it 'delega al proveedor de usuarios' do
      allow_any_instance_of(ProveedorUsuarios).to receive(:penalizar_si_corresponde).with(contexto[:email]).and_return(instance_double('ResultadoPenalizacion', exito?: true))

      resultado = proveedor.penalizar_si_corresponde(contexto[:email])

      expect(resultado.exito?).to be true
    end
  end

  describe '#version' do
    it 'delega al proveedor de comandos' do
      allow_any_instance_of(ProveedorComandos).to receive(:version).and_return(instance_double('ResultadoVersion', version: '1.0.0'))

      resultado = proveedor.version

      expect(resultado.version).to eq('1.0.0')
    end
  end

  describe '#solicitar_medicos_disponibles' do
    it 'delega al proveedor de médicos' do
      allow_any_instance_of(ProveedorMedicos).to receive(:solicitar_medicos_disponibles).and_return(instance_double('ResultadoMedicosDisponibles', exito?: true))

      resultado = proveedor.solicitar_medicos_disponibles

      expect(resultado.exito?).to be true
    end
  end

  describe '#solicitar_especialidades_disponibles' do
    it 'delega al proveedor de médicos' do
      allow_any_instance_of(ProveedorMedicos).to receive(:solicitar_especialidades_disponibles).and_return(instance_double('ResultadoEspecialidadesDisponibles', exito?: true))

      resultado = proveedor.solicitar_especialidades_disponibles

      expect(resultado.exito?).to be true
    end
  end

  describe '#solicitar_medicos_por_especialidad_disponibles' do
    it 'delega al proveedor de médicos' do
      resultado_mock = instance_double('ResultadoMedicosPorEspecialidadDisponibles', exito?: true)
      allow_any_instance_of(ProveedorMedicos).to receive(:solicitar_medicos_por_especialidad_disponibles).with(contexto[:especialidad]).and_return(resultado_mock)

      resultado = proveedor.solicitar_medicos_por_especialidad_disponibles(contexto[:especialidad])

      expect(resultado.exito?).to be true
    end
  end

  describe '#solicitar_turnos_disponibles' do
    it 'delega al proveedor de turnos' do
      allow_any_instance_of(ProveedorTurnos).to receive(:solicitar_turnos_disponibles).with(contexto[:matricula],
                                                                                            contexto[:especialidad]).and_return(instance_double('ResultadoTurnosDisponibles', exito?: true))

      resultado = proveedor.solicitar_turnos_disponibles(contexto[:matricula], contexto[:especialidad])

      expect(resultado.exito?).to be true
    end
  end

  describe '#reservar_turno' do
    it 'delega al proveedor de turnos' do
      allow_any_instance_of(ProveedorTurnos).to receive(:reservar_turno).with(contexto[:matricula], contexto[:fecha], contexto[:hora],
                                                                              contexto[:email]).and_return(instance_double('ResultadoReserva', exito?: true))

      resultado = proveedor.reservar_turno(contexto[:matricula], contexto[:fecha], contexto[:hora], contexto[:email])

      expect(resultado.exito?).to be true
    end
  end

  describe '#solicitar_proximos_turnos' do
    it 'delega al proveedor de turnos' do
      allow_any_instance_of(ProveedorTurnos).to receive(:solicitar_proximos_turnos).with(contexto[:email]).and_return(instance_double('ResultadoProximosTurnos', exito?: true))

      resultado = proveedor.solicitar_proximos_turnos(contexto[:email])

      expect(resultado.exito?).to be true
    end
  end

  describe '#solicitar_historial_turnos' do
    it 'delega al proveedor de turnos' do
      allow_any_instance_of(ProveedorTurnos).to receive(:solicitar_historial_turnos).with(contexto[:email]).and_return(instance_double('ResultadoHistorialTurnos', exito?: true))

      resultado = proveedor.solicitar_historial_turnos(contexto[:email])

      expect(resultado.exito?).to be true
    end
  end

  describe '#cancelar_turno' do
    it 'delega al proveedor de turnos' do
      confirmacion = true
      allow_any_instance_of(ProveedorTurnos).to receive(:cancelar_turno).with(contexto[:turno_id], contexto[:email], confirmacion).and_return(instance_double('ResultadoCancelarTurno', exito?: true))

      resultado = proveedor.cancelar_turno(contexto[:turno_id], contexto[:email], confirmacion)

      expect(resultado.exito?).to be true
    end
  end
end
