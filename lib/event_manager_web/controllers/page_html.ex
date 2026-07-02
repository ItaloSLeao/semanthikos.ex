defmodule EventManagerWeb.PageHTML do
  @moduledoc """
  Módulo `EventManagerWeb.PageHTML`.

  Faz parte da estrutura base do Event Manager, localizado em `event_manager_web/controllers/page_html.ex`.
  Define lógicas, componentes ou rotas específicas dessa camada.
  Para detalhes mais profundos, consulte a documentação da arquitetura central (`EventManager.Core` e `EventManagerWeb.Router`).
  """
  use EventManagerWeb, :html
  embed_templates "templates/page/*"
end
