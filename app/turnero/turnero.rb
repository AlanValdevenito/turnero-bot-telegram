require_relative 'excepciones/no_hay_disponibilidad'

class Turnero
  def initialize(proveedor_turnero)
    @proveedor_turnero = proveedor_turnero
  end

  def usuario_registrado?(telegram_id)
    @proveedor_turnero.usuario_registrado?(telegram_id)
  end

  def registrar_paciente(email, telegram_id)
    @proveedor_turnero.crear_usuario(email, telegram_id)
  end

  def solicitar_medicos_disponibles
    # Tal vez sea mejor tener una clase medico para retornar los datos
    # de los medicos disponibles, pero por ahora retornamos un hash -> objetos
    medicos = @proveedor_turnero.solicitar_medicos_disponibles
    raise NoHayMedicosDisponiblesException if medicos.nil? || medicos.empty?

    medicos
  end

  def solicitar_turnos_disponibles(matricula, especialidad)
    # Tal vez sea mejor tener una clase turno para retornar los datos
    # de los turnos disponibles, pero por ahora retornamos un hash -> objetos
    turnos = @proveedor_turnero.solicitar_turnos_disponibles(matricula, especialidad)
    raise NohayTurnosDisponiblesException if turnos.nil? || turnos.empty?

    turnos
  end

  def reservar_turno(matricula, fecha, hora, telegram_id)
    @proveedor_turnero.reservar_turno(matricula, fecha, hora, telegram_id)
  end
end
