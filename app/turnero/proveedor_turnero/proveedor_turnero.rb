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
require_relative 'proveedor_turnero_helpers'
# rubocop:disable Metrics/ClassLength
class ProveedorTurnero
  def initialize(api_url)
    @api_url = api_url
  end

  def version
    correlation_id = Thread.current[:cid]
    response = Faraday.get("#{@api_url}/version", {}, { 'cid' => correlation_id })
    JSON.parse(response.body)['version']
  end

  def usuario_registrado?(telegram_id)
    correlation_id = Thread.current[:cid]
    response = Faraday.get("#{@api_url}/usuarios/telegram/#{telegram_id}", {}, { 'cid' => correlation_id })
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
    correlation_id = Thread.current[:cid]
    body = { email:, telegram_id: }.to_json
    headers = { 'Content-Type' => 'application/json', 'cid' => correlation_id }
    response = Faraday.post("#{@api_url}/usuarios", body, headers)

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
    correlation_id = Thread.current[:cid]
    response = Faraday.get("#{@api_url}/turnos/medicos-disponibles", {}, { 'cid' => correlation_id })
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

  def solicitar_turnos_disponibles(matricula, _especialidad)
    correlation_id = Thread.current[:cid]
    response = Faraday.get("#{@api_url}/turnos/#{matricula}/disponibilidad", {}, { 'cid' => correlation_id })
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
    correlation_id = Thread.current[:cid]
    body = { matricula:, fecha:, hora:, email: }.to_json
    headers = { 'Content-Type' => 'application/json', 'cid' => correlation_id }
    response = Faraday.post("#{@api_url}/turnos", body, headers)
    manejar_respuesta_reserva(response)
  rescue Faraday::Error
    raise ErrorConexionAPI
  end

  def solicitar_proximos_turnos(email)
    correlation_id = Thread.current[:cid]
    response = Faraday.get("#{@api_url}/turnos/pacientes/proximos/#{email}", {}, { 'cid' => correlation_id })
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
    correlation_id = Thread.current[:cid]
    response = Faraday.get("#{@api_url}/turnos/pacientes/historial/#{email}", {}, { 'cid' => correlation_id })
    case response.status
    when 200..299
      turnos = parsear_historial_turnos(JSON.parse(response.body))
      ResultadoHistorialTurnos.new(exito: true, turnos:)
    when 400..499
      error = JSON.parse(response.body)['error']
      ResultadoHistorialTurnos.new(exito: false, error:)
    end
  end

  private

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
