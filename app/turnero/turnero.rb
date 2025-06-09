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
    turnos_hash = @proveedor_turnero.solicitar_turnos_disponibles(matricula, especialidad)
    raise NohayTurnosDisponiblesException if turnos_hash.nil? || turnos_hash.empty?

    turnos_hash.map do |hash|
      Turno.new
           .con_fecha(hash['fecha'])
           .con_hora(hash['hora'])
           .con_matricula(hash['matricula'])
    end
  end

  def reservar_turno(matricula, fecha, hora, telegram_id)
    @proveedor_turnero.reservar_turno(matricula, fecha, hora, telegram_id)
  end
end
