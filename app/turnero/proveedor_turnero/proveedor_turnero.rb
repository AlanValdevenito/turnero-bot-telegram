require 'json'
require_relative '../excepciones/errores_api'
require_relative '../excepciones/errores_conexion'
require_relative './resultados.rb/resultado_reserva'
require_relative './resultados.rb/resultado_turnos_disponibles'
require_relative './resultados.rb/resultado_medicos_disponibles'
require_relative './resultados.rb/resultado_crear_usuario'
require_relative './resultados.rb/resultado_proximos_turnos'
require_relative './resultados.rb/resultado_historial_turnos'
require_relative './resultados.rb/resultado_registrado'
require_relative './resultados.rb/resultado_especialidades_disponibles'
require_relative './resultados.rb/resultado_cancelar_turno'
require_relative './resultados.rb/resultado_penalizacion'
require_relative 'proveedor_turnero_helpers'
# rubocop:disable Metrics/ClassLength
class ProveedorTurnero
  def initialize(api_url, api_key)
    @api_url = api_url
    @api_key = api_key
  end

  def version
    response = Faraday.get("#{@api_url}/version", {}, crear_header)
    JSON.parse(response.body)['version']
  end

  def usuario_registrado?(telegram_id)
    response = Faraday.get("#{@api_url}/usuarios/telegram/#{telegram_id}", {}, crear_header)
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

  def penalizar_si_corresponde(email)
    response = Faraday.get("#{@api_url}/usuarios/#{email}/penalizacion", {}, crear_header)
    case response.status
    when 200..299
      ResultadoPenalizacion.new(exito: true)
    when 400..499
      error = JSON.parse(response.body)['error']
      ResultadoPenalizacion.new(exito: false, error:)
    else
      raise ErrorAPIPenalizacionException
    end
  rescue Faraday::Error
    raise ErrorConexionAPI
  end

  def crear_usuario(email, telegram_id)
    body = { email:, telegram_id: }.to_json
    response = Faraday.post("#{@api_url}/usuarios", body, crear_header)

    case response.status
    when 200..299
      ResultadoCrearUsuario.new(exito: true)
    when 400..499
      error = JSON.parse(response.body)['error']
      ResultadoCrearUsuario.new(exito: false, error:)
    when 500..599
      raise ErrorAPICrearUsuarioException
    else
      raise StandardError, "Unexpected status code: #{response.status}"
    end
  rescue Faraday::Error
    raise ErrorConexionAPI
  end

  def solicitar_medicos_disponibles
    response = Faraday.get("#{@api_url}/turnos/medicos-disponibles", {}, crear_header)
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

  def solicitar_especialidades_disponibles
    response = Faraday.get("#{@api_url}/especialidades", {}, crear_header)

    case response.status
    when 200..299
      especialidades = parsear_especialidades(JSON.parse(response.body))
      ResultadoEspecialidadesDisponibles.new(exito: true, especialidades:)
    end
  rescue Faraday::Error
    raise ErrorConexionAPI
  end

  def solicitar_medicos_por_especialidad_disponibles(especialidad)
    respuesta = Faraday.get("#{@api_url}/turnos/medicos-disponibles/#{especialidad}", {}, crear_header)

    case respuesta.status
    when 200..299
      medicos = parsear_medicos(JSON.parse(respuesta.body))
      ResultadoMedicosDisponibles.new(exito: true, medicos:)
    when 400..499
      error = JSON.parse(respuesta.body)['error']
      ResultadoMedicosDisponibles.new(exito: false, error:)
    end
  rescue Faraday::Error
    raise ErrorConexionAPI
  end

  def solicitar_turnos_disponibles(matricula, _especialidad)
    response = Faraday.get("#{@api_url}/turnos/#{matricula}/disponibilidad", {}, crear_header)
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
    response = Faraday.post("#{@api_url}/turnos", body, crear_header)
    manejar_respuesta_reserva(response)
  rescue Faraday::Error
    raise ErrorConexionAPI
  end

  def solicitar_proximos_turnos(email)
    response = Faraday.get("#{@api_url}/turnos/pacientes/proximos/#{email}", {}, crear_header)
    case response.status
    when 200..299
      turnos = parsear_proximos_turnos(JSON.parse(response.body))
      ResultadoProximosTurnos.new(exito: true, turnos:)
    when 400..499
      error = JSON.parse(response.body)['error']
      ResultadoProximosTurnos.new(exito: false, error:)
    when 500..599
      raise ErrorAPIProximosTurnosException
    else
      raise StandardError, "Unexpected status code: #{response.status}"
    end
  rescue Faraday::Error
    raise ErrorConexionAPI
  end

  def solicitar_historial_turnos(email)
    response = Faraday.get("#{@api_url}/turnos/pacientes/historial/#{email}", {}, crear_header)
    case response.status
    when 200..299
      turnos = parsear_historial_turnos(JSON.parse(response.body))
      ResultadoHistorialTurnos.new(exito: true, turnos:)
    when 400..499
      error = JSON.parse(response.body)['error']
      ResultadoHistorialTurnos.new(exito: false, error:)
    end
  end

  def cancelar_turno(id, email, confirmacion)
    body = { email:, confirmacion: }
    response = Faraday.put("#{@api_url}/turnos/#{id}/cancelacion", body.to_json, crear_header)
    case response.status
    when 200..299
      ResultadoCancelarTurno.new(exito: true)
    when 403
      error = JSON.parse(response.body)['mensaje']
      ResultadoCancelarTurno.new(exito: false, error:)
    when 409
      error = JSON.parse(response.body)['mensaje']
      ResultadoCancelarTurno.new(exito: false, error:)
    end
  end

  private

  def crear_header
    correlation_id = Thread.current[:cid]
    { 'Content-Type' => 'application/json', 'cid' => correlation_id, 'X-API-KEY' => @api_key }
  end

  def manejar_respuesta_reserva(response)
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
  end
end
# rubocop:enable Metrics/ClassLength
