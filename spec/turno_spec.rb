require_relative '../app/turnero/turno'

RSpec.describe Turno do
  def expect_attributes(turno, fecha, hora, matricula)
    expect(turno.fecha).to eq(fecha)
    expect(turno.hora).to eq(hora)
    expect(turno.matricula).to eq(matricula)
  end

  def crear_turno(fecha, hora, matricula)
    described_class.new
                   .con_fecha(fecha)
                   .con_hora(hora)
                   .con_matricula(matricula)
  end

  it 'permite setear atributos con interfaces fluidas' do
    turno = crear_turno('2025-06-10', '10:00', '123')
    expect_attributes(turno, '2025-06-10', '10:00', '123')
  end
end
