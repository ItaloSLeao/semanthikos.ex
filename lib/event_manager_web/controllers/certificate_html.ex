defmodule EventManagerWeb.CertificateHTML do
  @moduledoc """
  Módulo `EventManagerWeb.CertificateHTML`.

  Faz parte da estrutura base do Event Manager, localizado em `event_manager_web/controllers/certificate_html.ex`.
  Define lógicas, componentes ou rotas específicas dessa camada.
  Para detalhes mais profundos, consulte a documentação da arquitetura central (`EventManager.Core` e `EventManagerWeb.Router`).
  """
  use EventManagerWeb, :html
  embed_templates "templates/certificate/*"
end
