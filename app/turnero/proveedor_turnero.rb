require 'json'
require_relative 'excepciones/email_en_uso_exception'
require_relative 'excepciones/errores_api'
require_relative 'excepciones/errores_reserva_turno'
require_relative 'excepciones/paciente_registrado_exception'
require_relative 'excepciones/errores_conexion'
require_relative 'excepciones/no_hay_disponibilidad'

class ProveedorTurnero
  def initialize(api_url)
    @api_url = api_url
  end

  def usuario_registrado?(telegram_id)
    url = "#{@api_url}/usuarios/telegram/#{telegram_id}"
    response = Faraday.get(url)
    case response.status
    when 200
      true
    when 404
      false
    else
      raise ErrorAPIVerificarUsuarioException
    end
  rescue Faraday::Error
    raise ErrorConexionAPI
  end

  def crear_usuario(email, telegram_id)
    payload = { email:, telegram_id: }.to_json
    response = Faraday.post("#{@api_url}/usuarios", payload, { 'Content-Type' => 'application/json' })

    case response.status
    when 200..299
      JSON.parse(response.body)
    when 400..499
      manejar_error_crear_usuario(response)
    when 500..599
      raise ErrorAPICrearUsuarioException
    else
      raise StandardError, "Unexpected status code: #{response.status}"
    end
  rescue Faraday::Error
    raise ErrorConexionAPI
  end

  def solicitar_medicos_disponibles
    response = Faraday.get("#{@api_url}/turnos/medicos-disponibles")
    case response.status
    when 200..299
      JSON.parse(response.body)
    when 500..599
      raise ErrorAPIMedicosDisponiblesException
    else
      raise StandardError, "Unexpected status code: #{response.status}"
    end
  rescue Faraday::Error
    raise ErrorConexionAPI
  end

  def solicitar_turnos_disponibles(matricula, _especialidad)
    response = Faraday.get("#{@api_url}/turnos/#{matricula}/disponibilidad")
    case response.status
    when 200..299
      JSON.parse(response.body)
    when 400..499
      manejar_error_turnos_disponibles(response)
    when 500..599
      raise ErrorAPITurnosDisponiblesException
    else
      raise StandardError, "Unexpected status code: #{response.status}"
    end
  rescue Faraday::Error
    raise ErrorConexionAPI
  end

  def reservar_turno(matricula, fecha, hora, telegram_id)
    payload = { matricula:, fecha:, hora:, telegram_id: }.to_json
    response = Faraday.post("#{@api_url}/turnos", payload, { 'Content-Type' => 'application/json' })

    case response.status
    when 200..299
      JSON.parse(response.body)
    when 400..499
      manejar_error_reserva_turno(response)
    when 500..599
      raise ErrorAPIReservarTurnoException
    else
      # Unhandled status code
      raise StandardError, "Unexpected status code: #{response.status}"
    end
  rescue Faraday::Error
    raise ErrorConexionAPI
  end

  private

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

  def manejar_error_turnos_disponibles(response)
    error = JSON.parse(response.body)['error']
    case error
    when /no hay turnos/i
      raise NohayTurnosDisponiblesException
    when /médico no encontrado/i
      raise MedicoNoEncontradoException
    else
      raise ErrorAPITurnosDisponiblesException, error
    end
  end

  def manejar_error_reserva_turno(response)
    error = JSON.parse(response.body)['error']
    case error
    when /médico no encontrado/i
      raise MedicoNoEncontradoException
    when /ya existe un turno/i
      raise TurnoYaExisteException
    else
      raise StandardError, error
    end
  end
end
