require 'json'
require_relative 'excepciones/email_en_uso_exception'
require_relative 'excepciones/paciente_registrado_exception'

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
