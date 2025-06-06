require_relative '../excepciones/no_hay_disponibilidad'
require_relative '../excepciones/errores_reserva_turno'
require_relative '../excepciones/email_en_uso_exception'

def manejar_error_crear_usuario(response)
  error = JSON.parse(response.body)['error']

  case error
  when /ya está en uso/i
    raise EmailYaEnUsoException
  when /paciente.*registrado/i
    raise PacienteYaRegistradoException
  else
    raise StandardError, error
  end
end

def manejar_error_turnos_disponibles(response)
  error = JSON.parse(response.body)['error']
  case error
  when /no hay turnos/i
    raise NohayTurnosDisponiblesException
  when /médico no encontrado/i
    raise MedicoNoEncontradoException
  else
    raise ErrorAPITurnosDisponiblesException, error
  end
end

def manejar_error_reserva_turno(response)
  error = JSON.parse(response.body)['error']
  case error
  when /médico no encontrado/i
    raise MedicoNoEncontradoException
  when /ya existe un turno/i
    raise TurnoYaExisteException
  else
    raise StandardError, error
  end
end
