require 'json'
require_relative '../../excepciones/errores_api'
require_relative '../../excepciones/errores_conexion'
require_relative '../proveedor_turnero_helpers'

class ProveedorMedicos
  def initialize(api_url, api_key)
    @api_url = api_url
    @api_key = api_key
  end

  def solicitar_medicos_disponibles
    response = Faraday.get("#{@api_url}/turnos/medicos-disponibles", {}, crear_header(@api_key))
    case response.status
    when 200..299
      medicos = parsear_medicos(JSON.parse(response.body))
      ResultadoMedicosDisponibles.new(exito: true, medicos:)
    when 500..599
      raise ErrorAPIMedicosDisponiblesException
    else
      raise StandardError, "Unexpected status code: #{response.status}"
    end
  rescue Faraday::Error
    raise ErrorConexionAPI
  end

  def solicitar_medicos_por_especialidad_disponibles(especialidad)
    response = Faraday.get("#{@api_url}/turnos/medicos-disponibles/#{especialidad}", {}, crear_header(@api_key))
    case response.status
    when 200..299
      medicos = parsear_medicos(JSON.parse(response.body))
      ResultadoMedicosDisponibles.new(exito: true, medicos:)
    when 400..499
      ResultadoMedicosDisponibles.new(exito: false, error: JSON.parse(response.body)['error'])
    end
  rescue Faraday::Error
    raise ErrorConexionAPI
  end

  def solicitar_especialidades_disponibles
    response = Faraday.get("#{@api_url}/especialidades", {}, crear_header(@api_key))
    case response.status
    when 200..299
      especialidades = parsear_especialidades(JSON.parse(response.body))
      ResultadoEspecialidadesDisponibles.new(exito: true, especialidades:)
    end
  rescue Faraday::Error
    raise ErrorConexionAPI
  end
end
