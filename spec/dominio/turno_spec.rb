require_relative '../../app/turnero/turno'

RSpec.describe Turno do
  def expect_turno_basico(turno, fecha, hora)
    expect(turno.fecha).to eq(fecha)
    expect(turno.hora).to eq(hora)
  end

  def expect_turno_con_medico(turno, medico)
    expect_medico_nombre_apellido(turno.medico, medico)
    expect_medico_matricula_especialidad(turno.medico, medico)
  end

  def expect_medico_nombre_apellido(medico_obj, medico_ref)
    aggregate_failures do
      expect(medico_obj.nombre).to eq(medico_ref.nombre)
      expect(medico_obj.apellido).to eq(medico_ref.apellido)
    end
  end

  def expect_medico_matricula_especialidad(medico_obj, medico_ref)
    aggregate_failures do
      expect(medico_obj.matricula).to eq(medico_ref.matricula)
      expect(medico_obj.especialidad).to eq(medico_ref.especialidad)
    end
  end

  def crear_turno_basico(fecha, hora)
    described_class.new
                   .con_fecha(fecha)
                   .con_hora(hora)
  end

  def anadir_medico(turno, medico)
    turno.con_medico(medico)
  end

  it 'permite setear atributos con interfaces fluidas' do
    medico = instance_double(Medico, nombre: 'Juan', apellido: 'Pérez', matricula: '123', especialidad: 'Cardiología')
    turno = crear_turno_basico('2025-06-10', '10:00')
    expect_turno_basico(turno, '2025-06-10', '10:00')
    anadir_medico(turno, medico)
    expect_turno_con_medico(turno, medico)
  end
end
