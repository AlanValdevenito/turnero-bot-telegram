require 'json'

class ProveedorTurnero
  def initialize(api_url)
    @api_url = api_url
  end

  def crear_usuario(email)
    response = Faraday.post("#{@api_url}/registrar", { email: }.to_json, { 'Content-Type' => 'application/json' })

    if response.success?
      JSON.parse(response.body)
    else
      raise StandardError
    end
  end
end
