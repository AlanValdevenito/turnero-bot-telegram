require "#{File.dirname(__FILE__)}/../lib/routing"
require "#{File.dirname(__FILE__)}/../lib/version"
require_relative 'rutas/index'

class Routes
  include Routing

  def self.setup
    RegistrarRoutes.register(self)
    PedirTurnoRoutes.register(self)
    AyudaRoutes.register(self)
    VersionRoutes.register(self)
    register_general_commands
  end

  def self.register_general_commands
    register_start_command
    register_say_hi_command
    register_stop_command
  end

  def self.register_start_command
    on_message '/start' do |bot, message|
      bot.api.send_message(chat_id: message.chat.id, text: "Hola, #{message.from.first_name}")
    end
  end

  def self.register_say_hi_command
    on_message_pattern %r{/say_hi (?<name>.*)} do |bot, message, args|
      bot.api.send_message(chat_id: message.chat.id, text: "Hola, #{args['name']}")
    end
  end

  def self.register_stop_command
    on_message '/stop' do |bot, message|
      bot.api.send_message(chat_id: message.chat.id, text: "Chau, #{message.from.username}")
    end
  end

  setup
end
