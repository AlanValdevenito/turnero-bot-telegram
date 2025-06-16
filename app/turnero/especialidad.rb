class Especialidad
  attr_accessor :nombre

  def con_nombre(nombre)
    @nombre = nombre
    self
  end
end
