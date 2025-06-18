require_relative '../medico'
require_relative '../turno'
require_relative '../especialidad'

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

def parsear_especialidades(especialidades)
  return [] if especialidades.nil? || especialidades.empty?

  especialidades.map do |hash|
    Especialidad.new
                .con_nombre(hash['nombre'])
  end
end

def parsear_proximos_turnos(turnos_hash)
  turnos_hash.map { |hash| build_turno_proximo(hash) }
end

def parsear_historial_turnos(turnos_hash)
  turnos_hash.map { |hash| build_turno_proximo(hash) }
end

def construir_medico(nombre, apellido, especialidad)
  Medico.new.con_nombre(nombre).con_apellido(apellido).con_especialidad(especialidad)
end

def construir_turno(id, fecha, hora, medico, estado)
  Turno.new
       .con_id(id)
       .con_fecha(fecha)
       .con_hora(hora)
       .con_medico(medico)
       .con_estado(estado)
end

def build_turno_proximo(hash)
  nombre, apellido = hash['medico'].to_s.split(' ', 2)
  fecha, hora = hash['fecha y hora'].split(' ')
  medico = construir_medico(nombre, apellido, hash['especialidad'])
  construir_turno(hash['id'], fecha, hora, medico, hash['estado'])
end

def crear_header
  correlation_id = Thread.current[:cid]
  { 'Content-Type' => 'application/json', 'cid' => correlation_id, 'X-API-KEY' => @api_key }
end

def manejar_respuesta_reserva(response)
  case response.status
  when 200..299
    ResultadoReserva.new(exito: true, turno: parsear_turno(JSON.parse(response.body)))
  when 400..499
    ResultadoReserva.new(exito: false, error: JSON.parse(response.body)['error'])
  when 500..599
    raise ErrorAPIReservarTurnoException
  else
    raise StandardError, "Unexpected status code: #{response.status}"
  end
end
