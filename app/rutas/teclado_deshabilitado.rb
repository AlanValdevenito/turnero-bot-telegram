class TecladoDeshabilitado
  DESHABILITAR = 'disabled'.freeze

  def self.disable_keyboard_buttons(bot, callback_query, selected_data)
    original_message = callback_query.message
    return unless original_message.reply_markup&.inline_keyboard

    new_keyboard = Telegram::Bot::Types::InlineKeyboardMarkup.new(
      inline_keyboard: build_disabled_buttons(original_message.reply_markup.inline_keyboard, selected_data)
    )

    bot.api.edit_message_reply_markup(
      chat_id: original_message.chat.id,
      message_id: original_message.message_id,
      reply_markup: new_keyboard
    )
  end

  def self.build_disabled_buttons(inline_keyboard, selected_data)
    inline_keyboard.map do |row|
      row.map { |button| build_disabled_button(button, selected_data) }
    end
  end

  def self.build_disabled_button(button, selected_data)
    if button.callback_data == selected_data
      Telegram::Bot::Types::InlineKeyboardButton.new(
        text: "[ #{button.text} ]",
        callback_data: DESHABILITAR
      )
    else
      Telegram::Bot::Types::InlineKeyboardButton.new(
        text: button.text.to_s,
        callback_data: DESHABILITAR
      )
    end
  end
end
