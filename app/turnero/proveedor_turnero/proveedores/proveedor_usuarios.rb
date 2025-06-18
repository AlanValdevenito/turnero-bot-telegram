require 'json'
require_relative '../../excepciones/errores_api'
require_relative '../../excepciones/errores_conexion'
require_relative '../proveedor_turnero_helpers'

class ProveedorUsuarios
  def initialize(api_url, api_key)
    @api_url = api_url
    @api_key = api_key
  end

  def usuario_registrado?(telegram_id)
    response = Faraday.get("#{@api_url}/usuarios/telegram/#{telegram_id}", {}, crear_header(@api_key))
    case response.status
    when 200..299
      email = JSON.parse(response.body)['email']
      ResultadoRegistrado.new(exito: true, email:)
    when 404
      error = JSON.parse(response.body)['error']
      ResultadoRegistrado.new(exito: false, error:)
    else
      raise ErrorAPIVerificarUsuarioException
    end
  rescue Faraday::Error
    raise ErrorConexionAPI
  end

  def crear_usuario(email, telegram_id)
    body = { email:, telegram_id: }.to_json
    response = Faraday.post("#{@api_url}/usuarios", body, crear_header(@api_key))
    case response.status
    when 200..299 then ResultadoCrearUsuario.new(exito: true)
    when 400..499 then ResultadoCrearUsuario.new(exito: false, error: JSON.parse(response.body)['error'])
    when 500..599 then raise ErrorAPICrearUsuarioException
    else raise StandardError, "Unexpected status code: #{response.status}"
    end
  rescue Faraday::Error
    raise ErrorConexionAPI
  end

  def penalizar_si_corresponde(email)
    response = Faraday.get("#{@api_url}/usuarios/#{email}/penalizacion", {}, crear_header(@api_key))
    case response.status
    when 200..299 then ResultadoPenalizacion.new(exito: true)
    when 400..499 then ResultadoPenalizacion.new(exito: false, error: JSON.parse(response.body)['error'])
    else raise ErrorAPIPenalizacionException
    end
  rescue Faraday::Error
    raise ErrorConexionAPI
  end
end
