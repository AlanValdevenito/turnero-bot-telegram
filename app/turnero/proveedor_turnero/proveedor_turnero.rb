require_relative 'proveedores/index'

class ProveedorTurnero
  def initialize(api_url, api_key)
    @proveedor_usuarios = ProveedorUsuarios.new(api_url, api_key)
    @proveedor_turnos = ProveedorTurnos.new(api_url, api_key)
    @proveedor_medicos = ProveedorMedicos.new(api_url, api_key)
    @proveedor_comandos = ProveedorComandos.new(api_url, api_key)
  end

  # Usuarios
  def usuario_registrado?(telegram_id)
    @proveedor_usuarios.usuario_registrado?(telegram_id)
  end

  def crear_usuario(email, telegram_id)
    @proveedor_usuarios.crear_usuario(email, telegram_id)
  end

  def penalizar_si_corresponde(email)
    @proveedor_usuarios.penalizar_si_corresponde(email)
  end

  # Información
  def version
    @proveedor_comandos.version
  end

  # Médicos y especialidades
  def solicitar_medicos_disponibles
    @proveedor_medicos.solicitar_medicos_disponibles
  end

  def solicitar_especialidades_disponibles
    @proveedor_medicos.solicitar_especialidades_disponibles
  end

  def solicitar_medicos_por_especialidad_disponibles(especialidad)
    @proveedor_medicos.solicitar_medicos_por_especialidad_disponibles(especialidad)
  end

  # Turnos
  def solicitar_turnos_disponibles(matricula, especialidad)
    @proveedor_turnos.solicitar_turnos_disponibles(matricula, especialidad)
  end

  def reservar_turno(matricula, fecha, hora, email)
    @proveedor_turnos.reservar_turno(matricula, fecha, hora, email)
  end

  def solicitar_proximos_turnos(email)
    @proveedor_turnos.solicitar_proximos_turnos(email)
  end

  def solicitar_historial_turnos(email)
    @proveedor_turnos.solicitar_historial_turnos(email)
  end

  def cancelar_turno(id, email, confirmacion)
    @proveedor_turnos.cancelar_turno(id, email, confirmacion)
  end
end
