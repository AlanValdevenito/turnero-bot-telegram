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
    resultado = @proveedor_turnero.solicitar_medicos_disponibles

    raise ErrorAPIMedicosDisponiblesException, resultado.error unless resultado.exito?

    raise NoHayMedicosDisponiblesException if resultado.medicos.nil? || resultado.medicos.empty?

    resultado.medicos
  end

  def solicitar_turnos_disponibles(matricula, especialidad)
    resultado = @proveedor_turnero.solicitar_turnos_disponibles(matricula, especialidad)

    unless resultado.exito?
      case resultado.error
      when /no hay turnos/i
        raise NohayTurnosDisponiblesException
      when /médico no encontrado/i
        raise MedicoNoEncontradoException
      else
        raise ErrorAPITurnosDisponiblesException, resultado.error
      end
    end

    resultado.turnos
  end

  def reservar_turno(matricula, fecha, hora, telegram_id)
    resultado = @proveedor_turnero.reservar_turno(matricula, fecha, hora, telegram_id)

    unless resultado.exito?
      case resultado.error
      when /ya existe un turno/i
        raise TurnoYaExisteException
      when /médico no encontrado/i
        raise MedicoNoEncontradoException
      else
        raise ErrorAPIReservarTurnoException, resultado.error
      end
    end

    resultado.turno
  end
end
