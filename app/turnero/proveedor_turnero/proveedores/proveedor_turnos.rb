require 'json'
require_relative '../../excepciones/errores_api'
require_relative '../../excepciones/errores_conexion'
require_relative '../proveedor_turnero_helpers'
require_relative '../resultados/index'

class ProveedorTurnos
  def initialize(api_url, api_key)
    @api_url = api_url
    @api_key = api_key
  end

  def solicitar_turnos_disponibles(matricula, _especialidad)
    response = Faraday.get("#{@api_url}/turnos/#{matricula}/disponibilidad", {}, crear_header(@api_key))
    case response.status
    when 200..299
      turnos_disponibles = parsear_turnos(JSON.parse(response.body))
      ResultadoTurnosDisponibles.new(exito: true, turnos: turnos_disponibles)
    when 400..499
      error = JSON.parse(response.body)['error']
      ResultadoTurnosDisponibles.new(exito: false, error:)
    when 500..599
      raise ErrorAPITurnosDisponiblesException
    else
      raise StandardError, "Unexpected status code: #{response.status}"
    end
  rescue Faraday::Error
    raise ErrorConexionAPI
  end

  def reservar_turno(matricula, fecha, hora, email)
    body = { matricula:, fecha:, hora:, email: }.to_json
    response = Faraday.post("#{@api_url}/turnos", body, crear_header(@api_key))
    case response.status
    when 200..299
      ResultadoReserva.new(exito: true, turno: parsear_turno(JSON.parse(response.body)))
    when 400..499
      ResultadoReserva.new(exito: false, error: JSON.parse(response.body)['error'])
    when 500..599
      raise ErrorAPIReservarTurnoException
    else
      raise StandardError, "Unexpected status code: #{response.status}"
    end
  rescue Faraday::Error
    raise ErrorConexionAPI
  end

  def solicitar_proximos_turnos(email)
    response = Faraday.get("#{@api_url}/turnos/pacientes/proximos/#{email}", {}, crear_header(@api_key))
    case response.status
    when 200..299
      turnos = parsear_proximos_turnos(JSON.parse(response.body))
      ResultadoProximosTurnos.new(exito: true, turnos:)
    when 400..499
      ResultadoProximosTurnos.new(exito: false, error: JSON.parse(response.body)['error'])
    when 500..599
      raise ErrorAPIProximosTurnosException
    else
      raise StandardError, "Unexpected status code: #{response.status}"
    end
  rescue Faraday::Error
    raise ErrorConexionAPI
  end

  def solicitar_historial_turnos(email)
    response = Faraday.get("#{@api_url}/turnos/pacientes/historial/#{email}", {}, crear_header(@api_key))
    case response.status
    when 200..299
      turnos = parsear_historial_turnos(JSON.parse(response.body))
      ResultadoHistorialTurnos.new(exito: true, turnos:)
    when 400..499
      ResultadoHistorialTurnos.new(exito: false, error: JSON.parse(response.body)['error'])
    end
  rescue Faraday::Error
    raise ErrorConexionAPI
  end

  def cancelar_turno(id, email, confirmacion)
    body = { email:, confirmacion: }.to_json
    response = Faraday.put("#{@api_url}/turnos/#{id}/cancelacion", body, crear_header(@api_key))
    case response.status
    when 200..299
      ResultadoCancelarTurno.new(exito: true)
    when 403, 409
      ResultadoCancelarTurno.new(exito: false, error: JSON.parse(response.body)['mensaje'])
    end
  rescue Faraday::Error
    raise ErrorConexionAPI
  end
end
