require 'json'
require_relative '../excepciones/email_en_uso_exception'
require_relative '../excepciones/errores_api'
require_relative '../excepciones/errores_conexion'
require_relative '../excepciones/paciente_registrado_exception'
require_relative './resultados.rb/resultado_reserva'
require_relative './resultados.rb/resultado_turnos_disponibles'
require_relative 'proveedor_turnero_helpers'

class ProveedorTurnero
  def initialize(api_url)
    @api_url = api_url
  end

  def usuario_registrado?(telegram_id)
    url = "#{@api_url}/usuarios/telegram/#{telegram_id}"
    response = Faraday.get(url)
    case response.status
    when 200
      true
    when 404
      false
    else
      raise ErrorAPIVerificarUsuarioException
    end
  rescue Faraday::Error
    raise ErrorConexionAPI
  end

  def crear_usuario(email, telegram_id)
    payload = { email:, telegram_id: }.to_json
    response = Faraday.post("#{@api_url}/usuarios", payload, { 'Content-Type' => 'application/json' })

    case response.status
    when 200..299
      JSON.parse(response.body)
    when 400..499
      manejar_error_crear_usuario(response)
    when 500..599
      raise ErrorAPICrearUsuarioException
    else
      raise StandardError, "Unexpected status code: #{response.status}"
    end
  rescue Faraday::Error
    raise ErrorConexionAPI
  end

  def solicitar_medicos_disponibles
    response = Faraday.get("#{@api_url}/turnos/medicos-disponibles")
    case response.status
    when 200..299
      JSON.parse(response.body)
    when 500..599
      raise ErrorAPIMedicosDisponiblesException
    else
      raise StandardError, "Unexpected status code: #{response.status}"
    end
  rescue Faraday::Error
    raise ErrorConexionAPI
  end

  def solicitar_turnos_disponibles(matricula, _especialidad)
    response = Faraday.get("#{@api_url}/turnos/#{matricula}/disponibilidad")
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

  def reservar_turno(matricula, fecha, hora, telegram_id)
    response = Faraday.post("#{@api_url}/turnos", { matricula:, fecha:, hora:, telegram_id: }.to_json, { 'Content-Type' => 'application/json' })
    case response.status
    when 200..299
      turno = parsear_turno(JSON.parse(response.body))
      ResultadoReserva.new(exito: true, turno:)
    when 400..499
      error = JSON.parse(response.body)['error']
      ResultadoReserva.new(exito: false, error:)
    when 500..599
      raise ErrorAPIReservarTurnoException
    else
      raise StandardError, "Unexpected status code: #{response.status}"
    end
  rescue Faraday::Error
    raise ErrorConexionAPI
  end

  private

  def parsear_turno(turno_hash)
    medico_hash = turno_hash['medico']
    medico = Medico.new
                   .con_nombre(medico_hash['nombre'])
                   .con_apellido(medico_hash['apellido'])
                   .con_matricula(medico_hash['matricula'])
                   .con_especialidad(medico_hash['especialidad'])
    Turno.new
         .con_fecha(turno_hash['fecha'])
         .con_hora(turno_hash['hora'])
         .con_medico(medico)
  end

  def parsear_turnos(turnos_hash)
    turnos_hash.map do |hash|
      Turno.new
           .con_fecha(hash['fecha'])
           .con_hora(hash['hora'])
    end
  end
end
