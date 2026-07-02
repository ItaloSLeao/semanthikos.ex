defmodule EventManagerWeb.AdminHTML do
  @moduledoc """
  Módulo `EventManagerWeb.AdminHTML`.

  Faz parte da estrutura base do Event Manager, localizado em `event_manager_web/controllers/admin_html.ex`.
  Define lógicas, componentes ou rotas específicas dessa camada.
  Para detalhes mais profundos, consulte a documentação da arquitetura central (`EventManager.Core` e `EventManagerWeb.Router`).
  """
  use EventManagerWeb, :html
  embed_templates "templates/admin/*"
end
