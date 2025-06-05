MENSAJE_NO_REGISTRADO = 'No está registrado, use el comando /registrar {email}'.freeze
MENSAJE_REGISTRO_EXITOSO = 'Registración exitosa'.freeze
MENSAJE_EMAIL_EN_USO = 'El email ingresado ya está en uso'.freeze
MENSAJE_YA_REGISTRADO = 'Ya se encuentra registrado'.freeze
MENSAJE_ERROR_GENERAL = 'Ups, error inesperado, por favor intente nuevamente más tarde'.freeze
MENSAJE_NO_MEDICOS = 'No hay médicos disponibles en este momento'.freeze
MENSAJE_ERROR_MEDICOS = 'Error al obtener la lista de médicos disponibles'.freeze
MENSAJE_NO_TURNOS = 'No hay turnos disponibles para este médico'.freeze
MENSAJE_ERROR_TURNOS = 'Error al obtener los turnos disponibles'.freeze
MENSAJE_ERROR_RESERVA = 'Error al reservar el turno'.freeze
MENSAJE_TURNO_CONFIRMADO = "Turno agendado exitosamente:\nFecha: %<fecha>s\nHora: %<hora>s\nMédico: %<medico>s\nEspecialidad: %<especialidad>s".freeze
MENSAJE_SELECCIONE_MEDICO = 'Seleccione un Médico'.freeze
MENSAJE_SELECCIONE_TURNO = 'Seleccione un turno'.freeze
MENSAJE_AYUDA = <<~TEXT.freeze
  Comandos disponibles:
  /registrar {email} - Registra tu email en el sistema
  /pedir-turno - Solicita un turno médico
TEXT
