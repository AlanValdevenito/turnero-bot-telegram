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
    medicos_hash = @proveedor_turnero.solicitar_medicos_disponibles
    raise NoHayMedicosDisponiblesException if medicos_hash.nil? || medicos_hash.empty?

    medicos_hash.map do |hash|
      Medico.new
            .con_nombre(hash['nombre'])
            .con_apellido(hash['apellido'])
            .con_matricula(hash['matricula'])
            .con_especialidad(hash['especialidad'])
    end
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
