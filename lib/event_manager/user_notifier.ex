defmodule EventManager.UserNotifier do
  import Swoosh.Email
  alias EventManager.Mailer

  def deliver_confirmation_instructions(user, url) do
    deliver(user.email, "Confirme sua conta", """
    Olá #{user.name},
    Confirme sua conta no Event Manager clicando no link abaixo:
    #{url}
    """)
  end

  def deliver_reset_password_instructions(user, url) do
    deliver(user.email, "Redefinir sua senha", """
    Olá #{user.name},
    Redefina sua senha clicando no link abaixo:
    #{url}
    """)
  end

  def deliver_update_email_instructions(user, url) do
    deliver(user.email, "Alterar seu email", """
    Olá #{user.name},
    Altere seu email clicando no link abaixo:
    #{url}
    """)
  end

  defp deliver(recipient, subject, body) do
    email =
      new()
      |> to(recipient)
      |> from({"Event Manager", "noreply@eventmanager.com"})
      |> subject(subject)
      |> text_body(body)

    with {:ok, _metadata} <- Mailer.deliver(email) do
      {:ok, email}
    end
  end
end