require 'json'
require_relative '../../excepciones/errores_api'
require_relative '../../excepciones/errores_conexion'
require_relative '../proveedor_turnero_helpers'
require_relative '../resultados/index'

class ProveedorComandos
  def initialize(api_url, api_key)
    @api_url = api_url
    @api_key = api_key
  end

  def version
    response = Faraday.get("#{@api_url}/version", {}, crear_header(@api_key))
    JSON.parse(response.body)['version']
  rescue Faraday::Error
    raise ErrorConexionAPI
  end
end
