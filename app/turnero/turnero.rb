require_relative 'excepciones/no_hay_disponibilidad'
require_relative 'excepciones/email_en_uso_exception'
require_relative 'excepciones/errores_reserva_turno'
require_relative 'excepciones/paciente_registrado_exception'
require_relative 'excepciones/usuario_no_registrado'
require_relative 'excepciones/errores_api'

class Turnero
  def initialize(proveedor_turnero)
    @proveedor_turnero = proveedor_turnero
  end

  def usuario_registrado?(telegram_id)
    registrado = @proveedor_turnero.usuario_registrado?(telegram_id)
    raise UsuarioNoRegistradoException unless registrado
  end

  def registrar_paciente(email, telegram_id)
    resultado = @proveedor_turnero.crear_usuario(email, telegram_id)

    unless resultado.exito?
      case resultado.error
      when /ya está en uso/i
        raise EmailYaEnUsoException
      when /paciente.*registrado/i
        raise PacienteYaRegistradoException
      else
        raise ErrorAPICrearUsuarioException, resultado.error
      end
    end
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
