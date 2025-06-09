class Turno
  attr_accessor :fecha, :hora, :matricula, :medico, :especialidad

  def con_fecha(fecha)
    @fecha = fecha
    self
  end

  def con_hora(hora)
    @hora = hora
    self
  end

  def con_matricula(matricula)
    @matricula = matricula
    self
  end

  def con_medico(medico)
    @medico = medico
    self
  end

  def con_especialidad(especialidad)
    @especialidad = especialidad
    self
  end
end
