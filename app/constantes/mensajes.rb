MENSAJE_NO_REGISTRADO = 'No está registrado, use el comando /registrar {email}'.freeze
MENSAJE_REGISTRO_EXITOSO = 'Registración exitosa'.freeze
MENSAJE_EMAIL_EN_USO = 'El email ingresado ya está en uso'.freeze
MENSAJE_YA_REGISTRADO = 'Ya se encuentra registrado'.freeze
MENSAJE_ERROR_GENERAL = 'Ups! error inesperado. Por favor intente nuevamente más tarde'.freeze
MENSAJE_NO_MEDICOS = 'No hay médicos disponibles en este momento'.freeze
MENSAJE_ERROR_MEDICOS = 'Error al obtener médicos disponibles. Por favor intente nuevamente'.freeze
MENSAJE_NO_TURNOS = 'No hay turnos disponibles para este médico'.freeze
MENSAJE_ERROR_TURNOS = 'Error al obtener turnos disponibles. Por favor intente nuevamente'.freeze
MENSAJE_ERROR_RESERVA = 'Error al agendar el turno. Por favor intente nuevamente'.freeze
MENSAJE_ERROR_TURNO_EXISTENTE = 'Error al agendar el turno, el turno ya no está disponible'.freeze
MENSAJE_TURNO_CONFIRMADO = "Turno agendado exitosamente:\nFecha: %<fecha>s\nHora: %<hora>s\nMédico: %<medico>s\nEspecialidad: %<especialidad>s".freeze
MENSAJE_SELECCIONE_MEDICO = 'Seleccione un médico'.freeze
MENSAJE_SELECCIONE_TURNO = 'Seleccione un turno'.freeze
MENSAJE_NO_HAY_TURNOS_PROXIMOS = 'No tiene próximos turnos. Puede agendar uno con el comando /pedir-turno'.freeze
MENSAJE_ERROR_API_PROXIMOS_TURNOS = 'Error al obtener los turnos próximos. Por favor intente nuevamente'.freeze
MENSAJE_NO_HAY_TURNOS_HISTORIAL = 'No tiene turnos en su historial'.freeze
MENSAJE_SELECCIONE_TIPO_RESERVA = 'Seleccione el tipo de reserva'.freeze
MENSAJE_SELECCIONE_ESPECIALIDAD = 'Seleccione una especialidad'.freeze
MENSAJE_NO_ESPECIALIDADES = 'No hay especialidades disponibles en este momento'.freeze
MENSAJE_NO_MEDICOS_ESPECIALIDAD = 'Ups, la especialidad elegida no tiene medicos dados de alta'.freeze
MENSAJE_AYUDA = <<~TEXT.freeze
  Comandos disponibles:
  /registrar {email} - Registra tu email en el sistema
  /pedir-turno - Solicita un turno médico
  /mis-turnos - Muestra tus próximos turnos
  /historial-turnos - Muestra tu historial de turnos
TEXT
MENSAJE_MEDICO_YA_SELECCIONADO = 'Ya seleccionaste un médico, para agendar un nuevo turno envía el mensaje: /pedir-turno'.freeze
MENSAJE_TURNO_YA_SELECCIONADO = 'Ya seleccionaste un turno, para seleccionar un nuevo médico envía el mensaje: /pedir-turno'.freeze
MENSAJE_TURNO_CANCELADO = '¡Uh! turno cancelado, esperamos que estes bien'.freeze
MENSAJE_PENALIZACION = 'Usted se encuentra penalizado, tendrá que esperar para sacar un nuevo turno'.freeze
MENSAJE_ESPECIALIDAD_YA_SELECCIONADA = 'Ya seleccionaste una especialidad, para agendar un nuevo turno envía el mensaje: /pedir-turno'.freeze
MENSAJE_TIPO_DE_RESERVA_YA_SELECCIONADO = 'Ya seleccionaste un tipo de reserva, para agendar un nuevo turno envía el mensaje: /pedir-turno'.freeze
MENSAJE_CONFIRMAR_CANCELACION_TURNO = 'Si cancelas el turno se te contará como ausente, ¿estás seguro que quieres cancelarlo?'.freeze
MENSAJE_TURNO_AUSENTE = 'Tu turno ha sido marcado como ausente por cancelarlo con poca anticipacion'.freeze
