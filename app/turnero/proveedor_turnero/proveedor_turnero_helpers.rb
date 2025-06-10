require_relative '../medico'
require_relative '../turno'

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
