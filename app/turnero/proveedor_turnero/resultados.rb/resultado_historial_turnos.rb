class ResultadoHistorialTurnos
  attr_reader :exito, :turnos, :error

  def initialize(exito:, turnos: nil, error: nil)
    @exito = exito
    @turnos = turnos
    @error = error
  end

  def exito?
    @exito
  end
end
