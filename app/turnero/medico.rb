class Medico
  attr_accessor :nombre, :apellido, :matricula, :especialidad

  def con_nombre(nombre)
    @nombre = nombre
    self
  end

  def con_apellido(apellido)
    @apellido = apellido
    self
  end

  def con_matricula(matricula)
    @matricula = matricula
    self
  end

  def con_especialidad(especialidad)
    @especialidad = especialidad
    self
  end
end
