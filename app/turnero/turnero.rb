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
    # Tal vez sea mejor tener una clase turno para retornar los datos
    # de los turnos disponibles, pero por ahora retornamos un hash -> objetos
    @proveedor_turnero.solicitar_turnos_disponibles(matricula, especialidad)
  end

  def reservar_turno(matricula, fecha, hora, telegram_id)
    @proveedor_turnero.reservar_turno(matricula, fecha, hora, telegram_id)
  end
end
