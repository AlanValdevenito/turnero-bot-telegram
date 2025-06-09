require_relative '../app/turnero/turno'

RSpec.describe Turno do
  def expect_turno_basico(turno, fecha, hora, matricula)
    expect(turno.fecha).to eq(fecha)
    expect(turno.hora).to eq(hora)
    expect(turno.matricula).to eq(matricula)
  end

  def expect_turno_con_medico(turno, medico, especialidad)
    expect(turno.medico).to eq(medico)
    expect(turno.especialidad).to eq(especialidad)
  end

  def crear_turno_basico(fecha, hora, matricula)
    described_class.new
                   .con_fecha(fecha)
                   .con_hora(hora)
                   .con_matricula(matricula)
  end

  def anadir_medico(turno, medico, especialidad)
    turno.con_medico(medico)
         .con_especialidad(especialidad)
  end

  it 'permite setear atributos con interfaces fluidas usando un mock de medico' do
    medico = instance_double(Medico, nombre: 'Juan', apellido: 'Pérez')
    turno = crear_turno_basico('2025-06-10', '10:00', '123')
    expect_turno_basico(turno, '2025-06-10', '10:00', '123')
    anadir_medico(turno, medico, 'Cardiología')
    expect_turno_con_medico(turno, medico, 'Cardiología')
  end
end
