class ResultadoCancelarTurno
  attr_reader :exito, :error

  def initialize(exito:, error: nil)
    @exito = exito
    @error = error
  end

  def exito?
    @exito
  end
end
