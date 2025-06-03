class Turnero
  def initialize(proveedor_turnero)
    @proveedor_turnero = proveedor_turnero
  end

  def registrar_paciente(email)
    @proveedor_turnero.crear_usuario(email)
  end
end
