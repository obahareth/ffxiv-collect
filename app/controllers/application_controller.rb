class ApplicationController < ActionController::Base
  before_action :set_locale, :set_characters

  SUPPORTED_LOCALES = %w(en de fr ja).freeze

  def new_session_path(scope)
    new_user_session_path
  end

  def redirect_to_previous
    redirect_to session.delete(:return_to) || root_path
  end

  def set_permanent_cookie(key, value)
    cookies[key] = { value: value, expires: 20.years.from_now, same_site: :lax }
  end

  def verify_signed_in!
    unless user_signed_in?
      flash[:alert] = t('alerts.not_signed_in')
      redirect_to_previous
    end
  end

  def verify_character!
    unless @character.present?
      flash[:alert] = t('alerts.character_not_selected')
      redirect_to root_path
    end
  end

  def log_backtrace(exception)
    Rails.logger.error(exception.inspect)
    exception.backtrace.first(3).each { |line| Rails.logger.error(line) }
  end

  private
  def set_locale
    locale = cookies[:locale]

    unless locale.present?
      locale = request.env['HTTP_ACCEPT_LANGUAGE']&.scan(/^[a-z]{2}/)&.first&.downcase

      unless locale.present? && SUPPORTED_LOCALES.include?(locale)
        locale = I18n.default_locale
      end

      set_permanent_cookie(:locale, locale)
    end

    I18n.locale = cookies[:locale]
  end

  def set_characters
    if user_signed_in?
      @character = current_user.character
      if @character&.private?(current_user)
        current_user.update(character_id: nil)
        flash[:error] = t('alerts.character_set_to_private')
        redirect_to root_path
      end
    elsif cookies[:character].present?
      @character = Character.find_by(id: cookies[:character])
      if @character&.private?
        cookies[:character] = nil
        flash[:error] = t('alerts.character_set_to_private')
        redirect_to root_path
      end
    end

    if cookies[:comparison].present?
      unless @character.present?
        cookies[:comparison] = nil
      end

      @comparison = Character.find_by(id: cookies[:comparison])
      if @comparison&.private?(current_user)
        cookies[:comparison] = nil
        flash[:error] = t('alerts.comparison_set_to_private')
        redirect_to root_path
      end
    end

    [@character, @comparison].each do |character|
      if character&.syncable?
        character.sync
      end
    end
  end
end
