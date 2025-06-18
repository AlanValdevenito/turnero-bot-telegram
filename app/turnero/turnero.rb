require_relative 'excepciones/index'

class Turnero
  def initialize(proveedor_turnero)
    @proveedor_turnero = proveedor_turnero
  end

  def version
    @proveedor_turnero.version
  end

  def usuario_registrado?(telegram_id)
    resultado = @proveedor_turnero.usuario_registrado?(telegram_id)
    raise UsuarioNoRegistradoException unless resultado.exito?

    resultado.email
  end

  def penalizar_si_corresponde(email)
    resultado = @proveedor_turnero.penalizar_si_corresponde(email)
    raise PenalizacionPorReputacionException unless resultado.exito?
  end

  def registrar_paciente(email, telegram_id)
    resultado = @proveedor_turnero.crear_usuario(email, telegram_id)

    unless resultado.exito?
      case resultado.error
      when /ya está en uso/i then raise EmailYaEnUsoException
      when /paciente.*registrado/i then raise PacienteYaRegistradoException
      else raise ErrorAPICrearUsuarioException, resultado.error
      end
    end
  end

  def solicitar_medicos_disponibles
    resultado = @proveedor_turnero.solicitar_medicos_disponibles

    raise ErrorAPIMedicosDisponiblesException, resultado.error unless resultado.exito?

    raise NoHayMedicosDisponiblesException if resultado.medicos.nil? || resultado.medicos.empty?

    resultado.medicos
  end

  def solicitar_especialidades_disponibles
    resultado = @proveedor_turnero.solicitar_especialidades_disponibles
    raise NoHayEspecialidadesDisponiblesException if resultado.especialidades.nil? || resultado.especialidades.empty?

    resultado.especialidades
  end

  def solicitar_medicos_por_especialidad_disponibles(especialidad)
    resultado = @proveedor_turnero.solicitar_medicos_por_especialidad_disponibles(especialidad)
    raise NoHayMedicosDisponiblesException if !resultado.exito? || resultado.medicos.nil? || resultado.medicos.empty?

    resultado.medicos
  end

  def solicitar_turnos_disponibles(matricula, especialidad)
    resultado = @proveedor_turnero.solicitar_turnos_disponibles(matricula, especialidad)

    unless resultado.exito?
      case resultado.error
      when /no hay turnos/i then raise NohayTurnosDisponiblesException
      when /médico no encontrado/i then raise MedicoNoEncontradoException
      else raise ErrorAPITurnosDisponiblesException, resultado.error
      end
    end

    resultado.turnos
  end

  def reservar_turno(matricula, fecha, hora, email)
    resultado = @proveedor_turnero.reservar_turno(matricula, fecha, hora, email)

    unless resultado.exito?
      case resultado.error
      when /ya existe un turno para ese médico/i then raise TurnoYaExisteException
      when /médico no encontrado/i then raise MedicoNoEncontradoException
      when /ya existe un turno reservado/i then raise SuperposicionDeTurnosException
      when /usuario ha alcanzado el límite de turnos/i then raise LimiteDeTurnosException
      else raise ErrorAPIReservarTurnoException, resultado.error
      end
    end

    resultado.turno
  end

  def proximos_turnos_paciente(email)
    resultado = @proveedor_turnero.solicitar_proximos_turnos(email)

    unless resultado.exito?
      case resultado.error
      when /El paciente no tiene/i then raise NoHayProximosTurnosException
      end
    end

    resultado.turnos
  end

  def historial_turnos_paciente(email)
    resultado = @proveedor_turnero.solicitar_historial_turnos(email)
    unless resultado.exito?
      case resultado.error
      when /El paciente no tiene turnos en su historial/i then raise NoHayTurnosEnHistorialException
      end
    end
    resultado.turnos
  end

  def cancelar_turno(id, email, confirmacion)
    resultado = @proveedor_turnero.cancelar_turno(id, email, confirmacion)
    unless resultado.exito?
      case resultado.error
      when /Necesitas confirmacion para cancelar este turno/i then raise CancelacionNecesitaConfirmacionException
      end
    end
  end
end
