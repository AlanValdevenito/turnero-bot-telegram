class Turno
  attr_accessor :id, :fecha, :hora, :medico, :estado

  def con_id(id)
    @id = id
    self
  end

  def con_fecha(fecha)
    @fecha = fecha
    self
  end

  def con_hora(hora)
    @hora = hora
    self
  end

  def con_medico(medico)
    @medico = medico
    self
  end

  def con_estado(estado)
    @estado = estado
    self
  end
end
