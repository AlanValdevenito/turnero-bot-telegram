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
