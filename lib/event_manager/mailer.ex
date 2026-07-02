defmodule EventManager.Mailer do
  @moduledoc """
  Mailer module for sending emails.
  Uses Swoosh for email delivery.
  """
  use Swoosh.Mailer, otp_app: :event_manager
end
