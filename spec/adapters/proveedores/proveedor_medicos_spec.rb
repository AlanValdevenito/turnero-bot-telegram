require 'spec_helper'
require 'webmock/rspec'
require_relative '../../../app/turnero/proveedor_turnero/proveedores/proveedor_medicos'

describe ProveedorMedicos do
  let(:api_url) { ENV['API_URL'] || 'http://fake-api' }
  let(:api_key) { ENV['API_KEY'] || 'fake-key' }
  let(:proveedor) { described_class.new(api_url, api_key) }
  let(:medicos_disponibles) do
    [
      { 'nombre' => 'Carlos', 'apellido' => 'Sanchez', 'matricula' => '123', 'especialidad' => 'Clínica' },
      { 'nombre' => 'Maria', 'apellido' => 'Perez', 'matricula' => '456', 'especialidad' => 'Pediatría' }
    ]
  end

  def expect_medicos_coinciden(medicos_obj, medicos_hash)
    expect(medicos_obj.size).to eq(medicos_hash.size)
    medicos_obj.zip(medicos_hash).each do |medico_obj, medico_hash|
      expect_medico_coincide(medico_obj, medico_hash)
    end
  end

  def expect_medico_coincide(medico_obj, medico_hash)
    expect_medico_nombre_apellido(medico_obj, medico_hash)
    expect_medico_matricula_especialidad(medico_obj, medico_hash)
  end

  def expect_medico_nombre_apellido(medico_obj, medico_hash)
    aggregate_failures do
      expect(medico_obj.nombre).to eq(medico_hash['nombre'])
      expect(medico_obj.apellido).to eq(medico_hash['apellido'])
    end
  end

  def expect_medico_matricula_especialidad(medico_obj, medico_hash)
    aggregate_failures do
      expect(medico_obj.matricula).to eq(medico_hash['matricula'])
      expect(medico_obj.especialidad).to eq(medico_hash['especialidad'])
    end
  end

  describe '#solicitar_medicos_disponibles' do
    it 'obtiene la lista de médicos disponibles con todos los campos' do
      stub_request(:get, "#{api_url}/turnos/medicos-disponibles").to_return(status: 200, body: medicos_disponibles.to_json, headers: { 'Content-Type' => 'application/json' })

      resultado = proveedor.solicitar_medicos_disponibles

      expect(resultado).to be_a(ResultadoMedicosDisponibles)
      expect(resultado.exito?).to be true
      expect_medicos_coinciden(resultado.medicos, medicos_disponibles)
    end

    it 'los medicos son un array vacio si no hay disponibles' do
      stub_request(:get, "#{api_url}/turnos/medicos-disponibles")
        .to_return(status: 200, body: [].to_json, headers: { 'Content-Type' => 'application/json' })

      resultado = proveedor.solicitar_medicos_disponibles

      expect(resultado.exito?).to be true
      expect(resultado.medicos).to eq([])
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

  describe 'Solicitar especialidades disponibles' do
    def especialidades_disponibles
      [
        { 'nombre' => 'Traumatologia', 'duracion_de_turnos' => 10 },
        { 'nombre' => 'Dermatologia', 'duracion_de_turnos' => 15 }
      ]
    end

    def expect_comparar_especialidades(especialidades_resultado, especialidades_esperado)
      expect(especialidades_resultado.size).to eq(especialidades_esperado.size)
      especialidades_resultado.zip(especialidades_esperado).each do |especialidad_resultado, especialidad_esperado|
        expect(especialidad_resultado.nombre).to eq(especialidad_esperado['nombre'])
      end
    end

    it 'deberia obtener la lista de especialidades disponibles' do
      stub_request(:get, "#{api_url}/especialidades").to_return(status: 200, body: especialidades_disponibles.to_json, headers: { 'Content-Type' => 'application/json' })

      resultado = proveedor.solicitar_especialidades_disponibles

      expect(resultado).to be_a(ResultadoEspecialidadesDisponibles)
      expect(resultado.exito?).to be true
      expect_comparar_especialidades(resultado.especialidades, especialidades_disponibles)
    end

    it 'deberia manejar errores de conexión al solicitar especialidades disponibles' do
      stub_request(:get, "#{api_url}/especialidades")
        .to_raise(Faraday::Error.new('Error de conexión'))

      expect { proveedor.solicitar_especialidades_disponibles }.to raise_error(ErrorConexionAPI)
    end
  end

  describe 'Solicitar medicos por especialidad' do
    def medicos_por_especialidad_disponibles
      [
        { 'nombre' => 'Carlos', 'apellido' => 'Sanchez', 'matricula' => '123', 'especialidad' => 'Traumatologia' },
        { 'nombre' => 'Maria', 'apellido' => 'Perez', 'matricula' => '456', 'especialidad' => 'Traumatologia' }
      ]
    end

    def expect_comparar_medicos(medicos_resultado, medicos_esperado)
      expect_comparar_matricula_medicos(medicos_resultado, medicos_esperado)
      expect_comparar_especialidad_medicos(medicos_resultado, medicos_esperado)
    end

    def expect_comparar_matricula_medicos(medicos_resultado, medicos_esperado)
      expect(medicos_resultado.size).to eq(medicos_esperado.size)
      medicos_resultado.zip(medicos_esperado).each do |medico_resultado, medico_esperado|
        expect(medico_resultado.matricula).to eq(medico_esperado['matricula'])
      end
    end

    def expect_comparar_especialidad_medicos(medicos_resultado, medicos_esperado)
      expect(medicos_resultado.size).to eq(medicos_esperado.size)
      medicos_resultado.zip(medicos_esperado).each do |medico_resultado, medico_esperado|
        expect(medico_resultado.especialidad).to eq(medico_esperado['especialidad'])
      end
    end

    it 'deberia devolver un resultado con error si no hay medicos disponibles de la especialidad elegida' do
      stub_request(:get, "#{api_url}/turnos/medicos-disponibles/Traumatologia")
        .to_return(status: 404, body: { error: 'Especialidad sin medicos dados de alta' }.to_json, headers: { 'Content-Type' => 'application/json' })

      resultado = proveedor.solicitar_medicos_por_especialidad_disponibles('Traumatologia')
      expect(resultado.exito?).to be false
      expect(resultado.error).to eq('Especialidad sin medicos dados de alta')
    end

    it 'deberia obtener la lista de medicos por especialidad disponibles' do
      stub_request(:get, "#{api_url}/turnos/medicos-disponibles/Traumatologia").to_return(status: 200, body: medicos_por_especialidad_disponibles.to_json, headers: { 'Content-Type' => 'application/json' })

      resultado = proveedor.solicitar_medicos_por_especialidad_disponibles('Traumatologia')

      expect(resultado).to be_a(ResultadoMedicosDisponibles)
      expect(resultado.exito?).to be true
      expect_comparar_medicos(resultado.medicos, medicos_por_especialidad_disponibles)
    end

    it 'deberia manejar errores de conexión al solicitar medicos por especialidad disponibles' do
      stub_request(:get, "#{api_url}/turnos/medicos-disponibles/Traumatologia")
        .to_raise(Faraday::Error.new('Error de conexión'))

      expect { proveedor.solicitar_medicos_por_especialidad_disponibles('Traumatologia') }.to raise_error(ErrorConexionAPI)
    end
  end
end
