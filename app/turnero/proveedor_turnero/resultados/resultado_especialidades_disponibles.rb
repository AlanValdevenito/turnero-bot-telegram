class ResultadoEspecialidadesDisponibles
  attr_reader :exito, :especialidades, :error

  def initialize(exito:, especialidades: nil, error: nil)
    @exito = exito
    @especialidades = especialidades
    @error = error
  end

  def exito?
    @exito
  end
end
