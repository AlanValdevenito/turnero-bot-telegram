require 'json'
require_relative 'excepciones/email_en_uso_exception'

class ProveedorTurnero
  def initialize(api_url)
    @api_url = api_url
  end

  def crear_usuario(email, telegram_id)
    response = Faraday.post("#{@api_url}/registrar", { email:, telegram_id: }.to_json, { 'Content-Type' => 'application/json' })

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
    else
      raise StandardError
    end
  end
end
