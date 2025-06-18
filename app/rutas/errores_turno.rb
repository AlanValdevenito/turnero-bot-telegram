class ErroresTurno
  def self.handle_error_pedir_turno(bot, chat_id)
    yield
  rescue UsuarioNoRegistradoException
    bot.api.send_message(chat_id:, text: MENSAJE_NO_REGISTRADO)
  rescue NoHayEspecialidadesDisponiblesException
    bot.api.send_message(chat_id:, text: MENSAJE_NO_ESPECIALIDADES)
  rescue NoHayMedicosDisponiblesException
    bot.api.send_message(chat_id:, text: MENSAJE_NO_MEDICOS)
  rescue ErrorAPIMedicosDisponiblesException
    bot.api.send_message(chat_id:, text: MENSAJE_ERROR_MEDICOS)
  rescue ErrorAPIVerificarUsuarioException, ErrorConexionAPI
    bot.api.send_message(chat_id:, text: MENSAJE_ERROR_GENERAL)
  rescue PenalizacionPorReputacionException
    bot.api.send_message(chat_id:, text: MENSAJE_PENALIZACION)
  end

  def self.handle_error_seleccionar_especialidad(bot, chat_id)
    yield
  rescue NoHayMedicosDisponiblesException
    bot.api.send_message(chat_id:, text: MENSAJE_NO_MEDICOS_ESPECIALIDAD)
  end

  def self.handle_error_seleccionar_medico(bot, chat_id)
    yield
  rescue NohayTurnosDisponiblesException
    bot.api.send_message(chat_id:, text: MENSAJE_NO_TURNOS)
  rescue ErrorAPITurnosDisponiblesException
    bot.api.send_message(chat_id:, text: MENSAJE_ERROR_TURNOS)
  rescue ErrorConexionAPI
    bot.api.send_message(chat_id:, text: MENSAJE_ERROR_GENERAL)
  end

  def self.handle_error_seleccionar_turno(bot, chat_id)
    yield
  rescue TurnoYaExisteException
    bot.api.send_message(chat_id:, text: MENSAJE_ERROR_TURNO_EXISTENTE)
  rescue SuperposicionDeTurnosException
    bot.api.send_message(chat_id:, text: MENSAJE_ERROR_TURNO_CON_SUPERPOSICION)
  rescue ErrorAPIReservarTurnoException
    bot.api.send_message(chat_id:, text: MENSAJE_ERROR_RESERVA)
  rescue ErrorConexionAPI
    bot.api.send_message(chat_id:, text: MENSAJE_ERROR_GENERAL)
  rescue LimiteDeTurnosException
    bot.api.send_message(chat_id:, text: MENSAJE_LIMITE_TURNOS)
  end
end
