require 'json'
require_relative 'excepciones/email_en_uso_exception'
require_relative 'excepciones/paciente_registrado_exception'
require_relative 'excepciones/errores_api'

class ProveedorTurnero
  def initialize(api_url)
    @api_url = api_url
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
    raise ErrorAPIMedicosDisponiblesException
  end

  def solicitar_turnos_disponibles(matricula, _especialidad)
    response = Faraday.get("#{@api_url}/turnos/#{matricula}/disponibilidad")
    if response.success?
      JSON.parse(response.body)
    else
      raise ErrorAPITurnosDisponiblesException
    end
  rescue Faraday::Error
    raise ErrorAPITurnosDisponiblesException
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
