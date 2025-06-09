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

def parsear_turno(turno_hash)
  medico_hash = turno_hash['medico']
  medico = Medico.new
                 .con_nombre(medico_hash['nombre'])
                 .con_apellido(medico_hash['apellido'])
                 .con_matricula(medico_hash['matricula'])
                 .con_especialidad(medico_hash['especialidad'])
  Turno.new
       .con_fecha(turno_hash['fecha'])
       .con_hora(turno_hash['hora'])
       .con_medico(medico)
end

def parsear_turnos(turnos_hash)
  turnos_hash.map do |hash|
    Turno.new
         .con_fecha(hash['fecha'])
         .con_hora(hash['hora'])
  end
end

def parsear_medicos(medicos)
  return [] if medicos.nil? || medicos.empty?

  medicos.map do |hash|
    Medico.new
          .con_nombre(hash['nombre'])
          .con_apellido(hash['apellido'])
          .con_matricula(hash['matricula'])
          .con_especialidad(hash['especialidad'])
  end
end
