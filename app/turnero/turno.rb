class Turno
  attr_accessor :fecha, :hora, :matricula

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
end
