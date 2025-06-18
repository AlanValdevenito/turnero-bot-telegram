require_relative '../../app/turnero/medico'

RSpec.describe Medico do
  def expect_attributes(medico, nombre, apellido, matricula, especialidad)
    expect(medico.nombre).to eq(nombre)
    expect(medico.apellido).to eq(apellido)
    expect(medico.matricula).to eq(matricula)
    expect(medico.especialidad).to eq(especialidad)
  end

  def crear_medico(_nombre, _apellido, _matricula, _especialidad)
    described_class.new
                   .con_nombre('Juan')
                   .con_apellido('Pérez')
                   .con_matricula('123')
                   .con_especialidad('Clínica')
  end
  it 'permite setear atributos con interfaces fluidas' do
    medico = crear_medico('Juan', 'Pérez', '123', 'Clínica')
    expect_attributes(medico, 'Juan', 'Pérez', '123', 'Clínica')
  end
end
