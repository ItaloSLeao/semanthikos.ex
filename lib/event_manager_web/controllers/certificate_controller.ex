defmodule EventManagerWeb.CertificateController do
  @moduledoc """
  Controller for certificate viewing and downloading.
  """
  use EventManagerWeb, :controller

  def index(conn, _params) do
    user = conn.assigns.current_user
    certificates = EventManager.Services.list_user_certificates(user.id)

    render(conn, :index, certificates: certificates)
  end

  def show(conn, %{"id" => id}) do
    certificate = EventManager.Services.get_certificate!(id)
    user = conn.assigns.current_user

    if certificate.user_id == user.id do
      render(conn, :show, certificate: certificate)
    else
      conn
      |> put_flash(:error, "Você não tem permissão para acessar este certificado.")
      |> redirect(to: ~p"/my/certificates")
    end
  end

  def download(conn, %{"id" => id}) do
    certificate = EventManager.Services.get_certificate!(id)
    user = conn.assigns.current_user

    if certificate.user_id == user.id do
      # Entrega a versão em HTML, mas injeta um script para abrir a caixa de "Salvar como PDF" do navegador
      html_with_print =
        certificate.pdf_data <>
          "\n<script>window.onload = function() { setTimeout(function() { window.print(); }, 500); }</script>"

      conn
      |> put_resp_content_type("text/html")
      |> put_resp_header(
        "content-disposition",
        "inline; filename=\"certificado-#{certificate.certificate_number}.html\""
      )
      |> send_resp(200, html_with_print)
    else
      conn
      |> put_flash(:error, "Você não tem permissão para baixar este certificado.")
      |> redirect(to: ~p"/my/certificates")
    end
  end

  def verify(conn, %{"certificate_number" => certificate_number}) do
    case EventManager.Services.verify_certificate(certificate_number) do
      {:ok, result} ->
        render(conn, :verify, result: result, verified: true)

      {:error, :not_found} ->
        render(conn, :verify, result: nil, verified: false)
    end
  end

  def verify(conn, _params) do
    render(conn, :verify, result: nil, verified: nil)
  end
end
