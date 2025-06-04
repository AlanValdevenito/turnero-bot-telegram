class Turnero
  def initialize(proveedor_turnero)
    @proveedor_turnero = proveedor_turnero
  end

  def registrar_paciente(email, telegram_id)
    @proveedor_turnero.crear_usuario(email, telegram_id)
  end

  def solicitar_medicos_disponibles
    @proveedor_turnero.solicitar_medicos_disponibles
  end

  def solicitar_turnos_disponibles(matricula, especialidad)
    @proveedor_turnero.solicitar_turnos_disponibles(matricula, especialidad)
  end
end
