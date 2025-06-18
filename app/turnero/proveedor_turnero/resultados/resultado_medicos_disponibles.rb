class ResultadoMedicosDisponibles
  attr_reader :exito, :medicos, :error

  def initialize(exito:, medicos: nil, error: nil)
    @exito = exito
    @medicos = medicos
    @error = error
  end

  def exito?
    @exito
  end
end
