require 'spec_helper'
require 'web_mock'
require_relative '../app/turnero/proveedor_turnero/proveedor_turnero'
require_relative '../app/turnero/proveedor_turnero/resultados.rb/resultado_reserva'
require_relative '../app/turnero/proveedor_turnero/resultados.rb/resultado_turnos_disponibles'

describe 'ProveedorTurnero' do
  let(:datos_usuario) { { email: 'test@test.com', telegram_id: 1234 } }
  let(:api_url) { 'http://web:3000' }
  let(:proveedor) { ProveedorTurnero.new(api_url) }
  let(:medicos_disponibles) do
    [
      { 'nombre' => 'Carlos', 'apellido' => 'Sanchez', 'matricula' => '123', 'especialidad' => 'Clínica' },
      { 'nombre' => 'Maria', 'apellido' => 'Perez', 'matricula' => '456', 'especialidad' => 'Pediatría' }
    ]
  end
  let(:turnos_disponibles) do
    [
      { 'fecha' => '2024-06-05', 'hora' => '10:00', 'medico_id' => '123' },
      { 'fecha' => '2024-06-05', 'hora' => '11:00', 'medico_id' => '123' }
    ]
  end

  def cuando_quiero_registrar_usuario(email, telegram_id)
    stub_request(:post, "#{api_url}/usuarios")
      .with(body: { email:, telegram_id: })
      .to_return(status: 200, body: { message: 'El paciente se registró existosamente' }.to_json, headers: { 'Content-Type' => 'application/json' })
  end

  def cuando_quiero_registrar_usuario_email_en_uso(email, telegram_id)
    stub_request(:post, "#{api_url}/usuarios")
      .with(body: { email:, telegram_id: })
      .to_return(status: 400, body: { error: 'El email ingresado ya está en uso' }.to_json, headers: { 'Content-Type' => 'application/json' })
  end

  def cuando_quiero_registrar_paciente_ya_registrado(email, telegram_id)
    stub_request(:post, "#{api_url}/usuarios")
      .with(body: { email:, telegram_id: })
      .to_return(status: 400, body: { error: 'El paciente ya está registrado' }.to_json, headers: { 'Content-Type' => 'application/json' })
  end

  def crear_turno_exitoso(matricula, fecha, hora, telegram_id)
    stub_request(:post, "#{api_url}/turnos")
      .with(body: { matricula:, fecha:, hora:, telegram_id: })
      .to_return(status: 200, body: { message: 'Turno reservado exitosamente' }.to_json, headers: { 'Content-Type' => 'application/json' })
  end

  def stub_reserva_turno_exitosa(matricula:, fecha:, hora:)
    stub_request(:post, "#{api_url}/turnos")
      .with(body: { matricula:, fecha:, hora:, telegram_id: datos_usuario[:telegram_id] })
      .to_return(
        status: 200,
        body: {
          fecha:,
          hora:,
          medico: {
            nombre: 'Carlos',
            apellido: 'Sanchez',
            matricula:,
            especialidad: 'Clínica'
          }
        }.to_json,
        headers: { 'Content-Type' => 'application/json' }
      )
  end

  def stub_reserva_turno_error(status:, error:)
    stub_request(:post, "#{api_url}/turnos")
      .with(body: { matricula: '123', fecha: '2024-06-05', hora: '10:00', telegram_id: datos_usuario[:telegram_id] })
      .to_return(
        status:,
        body: { error: }.to_json,
        headers: { 'Content-Type' => 'application/json' }
      )
  end

  def expect_turno_reserva_exitosa(resultado, fecha:, hora:, medico:)
    aggregate_failures do
      expect(resultado).to be_a(ResultadoReserva)
      expect(resultado.exito?).to be true
      expect_turno_con_datos(resultado.turno, fecha:, hora:, medico:)
    end
  end

  def expect_turno_con_datos(turno, fecha:, hora:, medico:)
    aggregate_failures do
      expect(turno).to be_a(Turno)
      expect(turno.fecha).to eq(fecha)
      expect(turno.hora).to eq(hora)
      expect_turno_medico(turno.medico, medico)
    end
  end

  def expect_turno_medico(medico_obj, medico_hash)
    expect_medico_nombre_apellido(medico_obj, medico_hash)
    expect_medico_matricula_especialidad(medico_obj, medico_hash)
  end

  def expect_medico_nombre_apellido(medico_obj, medico_hash)
    aggregate_failures do
      expect(medico_obj.nombre).to eq(medico_hash[:nombre])
      expect(medico_obj.apellido).to eq(medico_hash[:apellido])
    end
  end

  def expect_medico_matricula_especialidad(medico_obj, medico_hash)
    aggregate_failures do
      expect(medico_obj.matricula).to eq(medico_hash[:matricula])
      expect(medico_obj.especialidad).to eq(medico_hash[:especialidad])
    end
  end

  it 'verifica si un usuario está registrado' do
    telegram_id = datos_usuario[:telegram_id]

    # Stub para usuario registrado
    stub_request(:get, "#{api_url}/usuarios/telegram/#{telegram_id}")
      .to_return(status: 200, body: { id: 1, email: datos_usuario[:email], telegram_id: }.to_json, headers: { 'Content-Type' => 'application/json' })

    expect(proveedor.usuario_registrado?(telegram_id)).to be true
  end

  it 'verifica si un usuario no está registrado' do
    telegram_id = datos_usuario[:telegram_id]

    # Stub para usuario no registrado
    stub_request(:get, "#{api_url}/usuarios/telegram/#{telegram_id}")
      .to_return(status: 404, body: { error: 'Usuario no encontrado' }.to_json, headers: { 'Content-Type' => 'application/json' })

    expect(proveedor.usuario_registrado?(telegram_id)).to be false
  end

  it 'maneja errores al verificar si un usuario está registrado' do
    telegram_id = datos_usuario[:telegram_id]

    # Stub para error de conexión
    stub_request(:get, "#{api_url}/usuarios/telegram/#{telegram_id}")
      .to_raise(Faraday::Error.new('Error de conexión'))

    expect { proveedor.usuario_registrado?(telegram_id) }.to raise_error(ErrorConexionAPI)
  end

  it 'maneja errores al verificar si un usuario está registrado con error de API' do
    telegram_id = datos_usuario[:telegram_id]

    # Stub para error de API
    stub_request(:get, "#{api_url}/usuarios/telegram/#{telegram_id}")
      .to_return(status: 500, body: { error: 'Error interno del servidor' }.to_json, headers: { 'Content-Type' => 'application/json' })

    expect { proveedor.usuario_registrado?(telegram_id) }.to raise_error(ErrorAPIVerificarUsuarioException)
  end

  context 'when crear_usuario' do
    it 'crea un usuario exitosamente' do
      cuando_quiero_registrar_usuario(datos_usuario[:email], datos_usuario[:telegram_id])
      response_body = { message: 'El paciente se registró existosamente' }.to_json
      response = proveedor.crear_usuario(datos_usuario[:email], datos_usuario[:telegram_id])
      expect(response).to eq(JSON.parse(response_body))
    end

    it 'intenta crear un usuario con un email ya en uso -> falla' do
      cuando_quiero_registrar_usuario_email_en_uso(datos_usuario[:email], datos_usuario[:telegram_id])
      expect { proveedor.crear_usuario(datos_usuario[:email], datos_usuario[:telegram_id]) }.to raise_error(EmailYaEnUsoException)
    end

    it 'intenta crear un usuario que ya está registrado -> falla' do
      cuando_quiero_registrar_paciente_ya_registrado(datos_usuario[:email], datos_usuario[:telegram_id])
      expect { proveedor.crear_usuario(datos_usuario[:email], datos_usuario[:telegram_id]) }.to raise_error(PacienteYaRegistradoException)
    end

    it 'maneja errores de conexión al crear un usuario' do
      stub_request(:post, "#{api_url}/usuarios")
        .with(body: { email: datos_usuario[:email], telegram_id: datos_usuario[:telegram_id] })
        .to_raise(Faraday::Error.new('Error de conexión'))
      expect { proveedor.crear_usuario(datos_usuario[:email], datos_usuario[:telegram_id]) }.to raise_error(ErrorConexionAPI)
    end

    it 'maneja errores de API al crear un usuario' do
      stub_request(:post, "#{api_url}/usuarios")
        .with(body: { email: datos_usuario[:email], telegram_id: datos_usuario[:telegram_id] })
        .to_return(status: 500, body: { error: 'Error interno del servidor' }.to_json, headers: { 'Content-Type' => 'application/json' })
      expect { proveedor.crear_usuario(datos_usuario[:email], datos_usuario[:telegram_id]) }.to raise_error(ErrorAPICrearUsuarioException)
    end
  end

  context 'when solicitar_medicos_disponibles' do
    it 'obtiene la lista de médicos disponibles con todos los campos' do
      stub_request(:get, "#{api_url}/turnos/medicos-disponibles")
        .to_return(status: 200, body: medicos_disponibles.to_json, headers: { 'Content-Type' => 'application/json' })

      response = proveedor.solicitar_medicos_disponibles

      expect(response).to eq(medicos_disponibles)
    end

    it 'maneja errores de API al solicitar médicos disponibles' do
      stub_request(:get, "#{api_url}/turnos/medicos-disponibles")
        .to_return(status: 500, body: { error: 'Error interno del servidor' }.to_json, headers: { 'Content-Type' => 'application/json' })

      expect { proveedor.solicitar_medicos_disponibles }.to raise_error(ErrorAPIMedicosDisponiblesException)
    end

    it 'maneja errores de conexión al solicitar médicos disponibles' do
      stub_request(:get, "#{api_url}/turnos/medicos-disponibles")
        .to_raise(Faraday::Error.new('Error de conexión'))

      expect { proveedor.solicitar_medicos_disponibles }.to raise_error(ErrorConexionAPI)
    end

    it 'devuelve un error genérico si la API devuelve un código de estado inesperado' do
      stub_request(:get, "#{api_url}/turnos/medicos-disponibles")
        .to_return(status: 300, body: { error: '300' }.to_json, headers: { 'Content-Type' => 'application/json' })

      expect { proveedor.solicitar_medicos_disponibles }.to raise_error(StandardError, /Unexpected status code/)
    end
  end

  context 'when solicitar_turnos_disponibles' do
    def expect_resultado_exitoso_turnos_disponibles(resultado)
      aggregate_failures do
        expect(resultado).to be_a(ResultadoTurnosDisponibles)
        expect(resultado.exito?).to be true
        expect_turnos_coinciden(resultado.turnos, turnos_disponibles)
      end
    end

    def expect_turnos_coinciden(turnos_obj, turnos_hash)
      expect(turnos_obj.size).to eq(turnos_hash.size)
      turnos_obj.zip(turnos_hash).each do |turno_obj, turno_hash|
        expect_turno_basico_coincide(turno_obj, turno_hash)
      end
    end

    def expect_turno_basico_coincide(turno_obj, turno_hash)
      aggregate_failures do
        expect(turno_obj.fecha).to eq(turno_hash['fecha'])
        expect(turno_obj.hora).to eq(turno_hash['hora'])
      end
    end
    it 'devuelve ResultadoTurnosDisponibles con turnos si la respuesta es exitosa' do
      stub_request(:get, "#{api_url}/turnos/123/disponibilidad")
        .to_return(status: 200, body: turnos_disponibles.to_json, headers: { 'Content-Type' => 'application/json' })

      resultado = proveedor.solicitar_turnos_disponibles('123', 'fake_especialidad')
      expect_resultado_exitoso_turnos_disponibles(resultado)
    end

    it 'devuelve ResultadoTurnosDisponibles con error si no hay turnos disponibles' do
      stub_request(:get, "#{api_url}/turnos/123/disponibilidad")
        .to_return(status: 400, body: { error: 'No hay turnos disponibles para este médico' }.to_json, headers: { 'Content-Type' => 'application/json' })

      resultado = proveedor.solicitar_turnos_disponibles('123', 'fake_especialidad')
      expect(resultado.exito?).to be false
      expect(resultado.error).to eq('No hay turnos disponibles para este médico')
    end

    it 'devuelve ResultadoTurnosDisponibles con error si el médico no existe' do
      stub_request(:get, "#{api_url}/turnos/123/disponibilidad")
        .to_return(status: 404, body: { error: 'Médico no encontrado' }.to_json, headers: { 'Content-Type' => 'application/json' })

      resultado = proveedor.solicitar_turnos_disponibles('123', 'fake_especialidad')
      expect(resultado.exito?).to be false
      expect(resultado.error).to eq('Médico no encontrado')
    end

    it 'lanza ErrorConexionAPI si hay un error de conexión' do
      matricula = '999'
      stub_request(:get, "#{api_url}/turnos/#{matricula}/disponibilidad")
        .to_raise(Faraday::Error.new('Error de conexión'))

      expect { proveedor.solicitar_turnos_disponibles(matricula, 'fake_especialidad') }.to raise_error(ErrorConexionAPI)
    end
  end

  context 'when reservar_turno' do
    it 'reserva un turno exitosamente' do
      stub_reserva_turno_exitosa(matricula: '123', fecha: '2024-06-05', hora: '10:00')
      resultado = proveedor.reservar_turno('123', '2024-06-05', '10:00', datos_usuario[:telegram_id])
      expect_turno_reserva_exitosa(resultado, fecha: '2024-06-05', hora: '10:00', medico: { nombre: 'Carlos', apellido: 'Sanchez', matricula: '123', especialidad: 'Clínica' })
    end

    it 'devuelve ResultadoReserva con error si el turno no está disponible' do
      stub_reserva_turno_error(status: 400, error: 'Ya existe un turno para ese médico y fecha/hora')

      resultado = proveedor.reservar_turno('123', '2024-06-05', '10:00', datos_usuario[:telegram_id])
      expect(resultado).to be_a(ResultadoReserva)
      expect(resultado.exito?).to be false
      expect(resultado.error).to eq('Ya existe un turno para ese médico y fecha/hora')
    end

    it 'devuelve ResultadoReserva con error si el médico no existe' do
      stub_reserva_turno_error(status: 404, error: 'Médico no encontrado')

      resultado = proveedor.reservar_turno('123', '2024-06-05', '10:00', datos_usuario[:telegram_id])
      expect(resultado).to be_a(ResultadoReserva)
      expect(resultado.exito?).to be false
      expect(resultado.error).to eq('Médico no encontrado')
    end

    it 'maneja errores de API internos al reservar un turno' do
      stub_request(:post, "#{api_url}/turnos")
        .with(body: { matricula: '123', fecha: '2024-06-05', hora: '10:00', telegram_id: datos_usuario[:telegram_id] })
        .to_return(status: 500, body: { error: 'Error interno del servidor' }.to_json, headers: { 'Content-Type' => 'application/json' })
      expect { proveedor.reservar_turno('123', '2024-06-05', '10:00', datos_usuario[:telegram_id]) }.to raise_error(ErrorAPIReservarTurnoException)
    end

    it 'maneja errores de conexión al reservar un turno' do
      stub_request(:post, "#{api_url}/turnos")
        .with(body: { matricula: '123', fecha: '2024-06-05', hora: '10:00', telegram_id: datos_usuario[:telegram_id] })
        .to_raise(Faraday::Error.new('Error de conexión'))

      expect { proveedor.reservar_turno('123', '2024-06-05', '10:00', datos_usuario[:telegram_id]) }.to raise_error(ErrorConexionAPI)
    end

    it 'devuelve un error genérico si la API devuelve un código de estado inesperado' do
      stub_request(:post, "#{api_url}/turnos")
        .with(body: { matricula: '123', fecha: '2024-06-05', hora: '10:00', telegram_id: datos_usuario[:telegram_id] })
        .to_return(status: 300, body: { error: '300' }.to_json, headers: { 'Content-Type' => 'application/json' })

      expect { proveedor.reservar_turno('123', '2024-06-05', '10:00', datos_usuario[:telegram_id]) }.to raise_error(StandardError, /Unexpected status code/)
    end
  end
end
