# TODO: Generalized Notifier service class
class PublisherNotifier
  attr_reader :notification_params, :notification_type, :publisher

  # Should match methods in NotificationMailer starting with #publisher_*
  NOTIFICATION_TYPES = %w(form_retry payments_activated)

  def initialize(notification_params: {}, notification_type:, publisher:)
    raise ":publisher invalid" if !publisher.is_a?(Publisher)
    @notification_type = notification_type.to_s
    if !NOTIFICATION_TYPES.include?(@notification_type)
      raise InvalidNotificationTypeError.new("#{notification_type} is an invalid notification_type")
    end
    @notification_params = (notification_params && notification_params.to_hash.symbolize_keys) || {}
    @publisher = publisher
  end

  def perform
    NotificationMailer.public_send(mailer_method, @publisher, notification_params).deliver_later
    if NotificationMailer.should_send_internal_emails? && NotificationMailer.respond_to?(mailer_method_internal)
      NotificationMailer.public_send(mailer_method_internal, @publisher, notification_params).deliver_later
    end
  end

  class InvalidNotificationTypeError < RuntimeError
  end

  private

  def mailer_method
    "publisher_#{notification_type}".to_sym
  end

  def mailer_method_internal
    "#{mailer_method}_internal".to_sym
  end
end
