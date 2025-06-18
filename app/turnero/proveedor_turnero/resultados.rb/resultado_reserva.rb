class ResultadoReserva
  attr_reader :exito, :turno, :error

  def initialize(exito:, turno: nil, error: nil)
    @exito = exito
    @turno = turno
    @error = error
  end

  def exito?
    @exito
  end
end
