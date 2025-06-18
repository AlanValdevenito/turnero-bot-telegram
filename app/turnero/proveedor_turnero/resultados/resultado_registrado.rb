class ResultadoRegistrado
  attr_reader :exito, :email, :error

  def initialize(exito:, email: nil, error: nil)
    @exito = exito
    @email = email
    @error = error
  end

  def exito?
    @exito
  end
end
