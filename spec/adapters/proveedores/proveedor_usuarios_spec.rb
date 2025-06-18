require 'spec_helper'
require 'webmock/rspec'
require_relative '../../../app/turnero/proveedor_turnero/proveedores/proveedor_usuarios'

describe ProveedorUsuarios do
  let(:api_url) { ENV['API_URL'] || 'http://fake-api' }
  let(:api_key) { ENV['API_KEY'] || 'fake-key' }
  let(:proveedor) { described_class.new(api_url, api_key) }
  let(:datos_usuario) { { email: 'test@test.com', telegram_id: 1234 } }

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

  describe '#usuario_registrado?' do
    it 'verifica si un usuario está registrado' do
      telegram_id = datos_usuario[:telegram_id]

      # Stub para usuario registrado
      stub_request(:get, "#{api_url}/usuarios/telegram/#{telegram_id}")
        .to_return(status: 200, body: { id: 1, email: datos_usuario[:email], telegram_id: }.to_json, headers: { 'Content-Type' => 'application/json' })

      resultado = proveedor.usuario_registrado?(telegram_id)
      expect(resultado.exito?).to be true
    end

    it 'verifica si un usuario no está registrado' do
      telegram_id = datos_usuario[:telegram_id]

      # Stub para usuario no registrado
      stub_request(:get, "#{api_url}/usuarios/telegram/#{telegram_id}")
        .to_return(status: 404, body: { error: 'Usuario no encontrado' }.to_json, headers: { 'Content-Type' => 'application/json' })

      resultado = proveedor.usuario_registrado?(telegram_id)
      expect(resultado.exito?).to be false
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
  end

  describe '#crear_usuario' do
    it 'crea un usuario exitosamente' do
      cuando_quiero_registrar_usuario(datos_usuario[:email], datos_usuario[:telegram_id])
      resultado = proveedor.crear_usuario(datos_usuario[:email], datos_usuario[:telegram_id])
      expect(resultado).to be_a(ResultadoCrearUsuario)
      expect(resultado.exito?).to be true
    end

    it 'intenta crear un usuario con un email ya en uso -> resultado con error' do
      cuando_quiero_registrar_usuario_email_en_uso(datos_usuario[:email], datos_usuario[:telegram_id])
      resultado = proveedor.crear_usuario(datos_usuario[:email], datos_usuario[:telegram_id])
      expect(resultado).to be_a(ResultadoCrearUsuario)
      expect(resultado.exito?).to be false
      expect(resultado.error).to eq('El email ingresado ya está en uso')
    end

    it 'intenta crear un usuario que ya está registrado -> resultado con error' do
      cuando_quiero_registrar_paciente_ya_registrado(datos_usuario[:email], datos_usuario[:telegram_id])
      resultado = proveedor.crear_usuario(datos_usuario[:email], datos_usuario[:telegram_id])
      expect(resultado).to be_a(ResultadoCrearUsuario)
      expect(resultado.exito?).to be false
      expect(resultado.error).to eq('El paciente ya está registrado')
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

  describe 'penalización por reputación' do
    it 'deberia devolver un resultado exitoso si no hay penalización por reputación' do
      stub_request(:get, "#{api_url}/usuarios/#{datos_usuario[:email]}/penalizacion")
        .to_return(status: 200, body: '', headers: { 'Content-Type' => 'application/json' })
      resultado = proveedor.penalizar_si_corresponde(datos_usuario[:email])
      expect(resultado.exito?).to be true
    end

    it 'deberia devolver un error si hay penalización por reputación' do
      stub_request(:get, "#{api_url}/usuarios/#{datos_usuario[:email]}/penalizacion")
        .to_return(status: 400, body: { error: 'Penalización por porcentaje de asistencia abajo del 80%' }.to_json, headers: { 'Content-Type' => 'application/json' })
      resultado = proveedor.penalizar_si_corresponde(datos_usuario[:email])
      expect(resultado.exito?).to be false
    end

    it 'deberia lanzar una excepción si hay un error de conexión al verificar penalización por reputación' do
      stub_request(:get, "#{api_url}/usuarios/#{datos_usuario[:email]}/penalizacion")
        .to_raise(Faraday::Error.new('Error de conexión'))
      expect { proveedor.penalizar_si_corresponde(datos_usuario[:email]) }.to raise_error(ErrorConexionAPI)
    end

    it 'deberia lanzar una excepción si hay un error de API al verificar penalización por reputación' do
      stub_request(:get, "#{api_url}/usuarios/#{datos_usuario[:email]}/penalizacion")
        .to_return(status: 500, body: { error: 'Error interno del servidor' }.to_json, headers: { 'Content-Type' => 'application/json' })
      expect { proveedor.penalizar_si_corresponde(datos_usuario[:email]) }.to raise_error(ErrorAPIPenalizacionException)
    end
  end
end
