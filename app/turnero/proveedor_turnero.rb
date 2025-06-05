require 'json'
require_relative 'excepciones/email_en_uso_exception'
require_relative 'excepciones/paciente_registrado_exception'
require_relative 'excepciones/errores_api'
require_relative 'excepciones/errores_conexion'

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

    if response.success?
      JSON.parse(response.body)
    else
      manejar_error(response)
    end
  end

  def solicitar_medicos_disponibles
    response = Faraday.get("#{@api_url}/turnos/medicos-disponibles")
    if response.success?
      JSON.parse(response.body)
    else
      raise ErrorAPIMedicosDisponiblesException
    end
  rescue Faraday::Error
    raise ErrorConexionAPI
  end

  def solicitar_turnos_disponibles(matricula, _especialidad)
    response = Faraday.get("#{@api_url}/turnos/#{matricula}/disponibilidad")
    if response.success?
      JSON.parse(response.body)
    else
      raise ErrorAPITurnosDisponiblesException
    end
  rescue Faraday::Error
    raise ErrorConexionAPI
  end

  def reservar_turno(matricula, fecha, hora, telegram_id)
    payload = { matricula:, fecha:, hora:, telegram_id: }.to_json
    response = Faraday.post("#{@api_url}/turnos", payload, { 'Content-Type' => 'application/json' })
    if response.success?
      JSON.parse(response.body)
    else
      raise ErrorAPIReservarTurnoException
    end
  rescue Faraday::Error
    raise ErrorConexionAPI
  end

  private

  def manejar_error(response)
    error = JSON.parse(response.body)['error']

    case error
    when /ya está en uso/i
      raise EmailYaEnUsoException
    when /paciente.*registrado/i
      raise PacienteYaRegistradoException
    else
      raise StandardError
    end
  end
end
