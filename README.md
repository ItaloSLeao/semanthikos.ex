# Semanthykos - Event Manager

![Elixir](https://img.shields.io/badge/Elixir-1.14+-purple.svg)
![Phoenix](https://img.shields.io/badge/Phoenix-1.7-blue.svg)
![PostgreSQL](https://img.shields.io/badge/PostgreSQL-14+-blue.svg)
![License](https://img.shields.io/badge/License-MIT-green.svg)

Sistema completo de gerenciamento de eventos acadêmicos desenvolvido em **Elixir** com **Phoenix Framework**, seguindo os requisitos da disciplina de Paradigmas de Linguagens de Programação (PLP).

## Visão Geral

Este sistema permite a gestão completa de eventos acadêmicos, incluindo:

- **Criação e gestão de eventos** com controle de vagas
- **Inscrições** com validação de disponibilidade em tempo real
- **Chat ao vivo** durante eventos para Q&A
- **Geração automática de certificados** em PDF
- **Dashboards e relatórios** com visualizações gráficas
- **Controle de acesso** baseado em papéis (RBAC)

## Stack Tecnológica

| Camada | Tecnologia | Justificativa |
|--------|-----------|---------------|
| **Backend** | Elixir + Phoenix Framework | Alta concorrência, tolerância a falhas, modelo de atores |
| **Banco de Dados** | PostgreSQL | Suporte a transações complexas, full-text search |
| **Web Server** | Nginx | Proxy reverso, serving de arquivos estáticos, SSL |
| **Frontend** | Phoenix LiveView | UI reativa sem JavaScript client-side |
| **Tempo Real** | Phoenix Channels | WebSockets para chat e notificações |

### Por que Elixir/Phoenix?

1. **Concorrência Massiva**: O modelo de atores do Erlang VM permite milhares de conexões WebSocket simultâneas
2. **Tolerância a Falhas**: Supervisores garantem que o sistema se recupere automaticamente de erros
3. **Hot Code Reloading**: Atualizações sem downtime
4. **Latência Baixa**: Processos leves com baixo overhead de memória
5. **LiveView**: Interface reativa sem necessidade de SPA frameworks

## Arquitetura

```
┌─────────────────────────────────────────────────────────────────┐
│                          Nginx                                  │
│  (SSL Termination, Static Files, Reverse Proxy, Load Balancer) │
└─────────────────────────────────────────────────────────────────┘
                               │
                               ▼
┌─────────────────────────────────────────────────────────────────┐
│                    Phoenix Endpoint (Port 4000)                │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────────┐ │
│  │ Controllers │  │  LiveView   │  │    Phoenix Channels     │ │
│  │   (HTTP)    │  │ (Real-time) │  │   (WebSockets/Chat)     │ │
│  └─────────────┘  └─────────────┘  └─────────────────────────┘ │
│                                                                 │
├─────────────────────────────────────────────────────────────────┤
│                        Business Logic                           │
│  ┌──────────────┐ ┌──────────────┐ ┌──────────────┐ ┌─────────┐│
│  │   Accounts   │ │    Events    │ │ Certificates │ │ Reports ││
│  │   Context    │ │   Context    │ │   Context    │ │ Context ││
│  └──────────────┘ └──────────────┘ └──────────────┘ └─────────┘│
│                                                                 │
├─────────────────────────────────────────────────────────────────┤
│                         Ecto Repo                               │
│                    (PostgreSQL Adapter)                         │
└─────────────────────────────────────────────────────────────────┘
                               │
                               ▼
┌─────────────────────────────────────────────────────────────────┐
│                        PostgreSQL                                │
│              (Users, Events, Registrations, etc.)               │
└─────────────────────────────────────────────────────────────────┘
```

### Estrutura de Diretórios

```
lib/
├── event_manager/                    # Camada de negócio (Contexts)
│   ├── accounts/                     # Gestão de usuários
│   │   ├── user.ex                   # Schema de usuário
│   │   ├── user_token.ex             # Tokens de sessão
│   │   ├── user_notifier.ex          # Notificações por email
│   │   └── accounts.ex               # Contexto de autenticação
│   ├── events/                       # Gestão de eventos
│   │   ├── event.ex                  # Schema de evento
│   │   ├── registration.ex           # Schema de inscrição
│   │   └── events.ex                 # Contexto de eventos
│   ├── certificates/                 # Geração de certificados
│   │   ├── certificate.ex            # Schema de certificado
│   │   ├── certificates.ex           # Lógica de geração PDF
│   │   └── certificate_worker.ex     # Worker assíncrono
│   ├── notifications/                # Chat e notificações
│   │   ├── chat_message.ex           # Schema de mensagem
│   │   └── notifications.ex          # Contexto de notificações
│   ├── reports/                      # Relatórios e dashboards
│   │   └── reports.ex                # Queries complexas
│   ├── application.ex                # OTP Application
│   └── repo.ex                       # Ecto Repository
├── event_manager_web/                # Camada web
│   ├── channels/                     # Phoenix Channels
│   │   ├── user_socket.ex            # WebSocket handler
│   │   ├── event_channel.ex          # Canal de eventos
│   │   └── chat_channel.ex           # Canal de chat
│   ├── controllers/                  # HTTP Controllers
│   ├── live/                         # LiveView modules
│   ├── components/                   # UI Components
│   ├── routers/                      # Rotas
│   └── templates/                    # HTML Templates
config/                               # Configurações
priv/
├── repo/migrations/                  # Migrações do banco
├── nginx/                            # Configuração Nginx
└── static/                           # Arquivos estáticos
```

## Funcionalidades

### 1. Autenticação e Autorização (RBAC)

Três níveis de acesso:

| Papel | Permissões |
|-------|-----------|
| **Admin** | Criar/editar eventos, gerenciar usuários, ver relatórios, gerar certificados |
| **Palestrante** | Ver seus eventos, marcar presença, responder perguntas no chat |
| **Estudante** | Inscrever-se em eventos, baixar certificados, participar do chat |

### 2. Gestão de Eventos

- Criação com campos: título, descrição, data, local, vagas, palestrante
- Controle de status: rascunho, publicado, em andamento, concluído, cancelado
- Validação de vagas com **optimistic locking**
- Busca full-text em português (PostgreSQL tsvector)

### 3. Sistema de Inscrições

- Reserva atômica de vagas (evita overbooking)
- Cancelamento com liberação de vaga
- Lista de espera (opcional)
- Confirmação de presença

### 4. Chat em Tempo Real

- Phoenix Channels para WebSockets
- Perguntas e respostas durante eventos
- Marcação de perguntas respondidas
- Histórico de mensagens persistente

### 5. Certificados

- Geração automática em PDF/HTML
- Número único de certificado
- Verificação pública por código
- Download pelo participante

### 6. Relatórios e Dashboards

- Taxa de ocupação por evento
- Participação por curso/departamento
- Estatísticas mensais
- Exportação CSV

## Instalação

### Pré-requisitos

- Elixir 1.14+
- Erlang/OTP 25+
- PostgreSQL 14+
- Node.js 18+ (para assets)
- Nginx (produção)

### Setup Local

```bash
# Clone o repositório
git clone https://github.com/ItaloSLeao/semanthykos-ex.git
cd event_manager

# Instale as dependências
mix local.hex --force
mix archive.install hex phx_new --force
mix deps.get

# Configure o banco de dados
# Edite config/dev.exs com suas credenciais do PostgreSQL

# Crie e popule o banco
mix ecto.setup

# Instale assets
mix assets.setup
mix assets.build

# Inicie o servidor
mix phx.server
```

Acesse: http://localhost:4000

### Comandos Principais

```bash
# Servidor com reload automático
mix phx.server

# Servidor interativo (IEx)
iex -S mix phx.server

# Console do banco
mix ecto.migrate

# Resetar banco
mix ecto.reset

# Executar testes
mix test

# Formatar código
mix format

# Verificar warnings
mix compile --warnings-as-errors
```

### WebSocket

```javascript
// Conectar ao canal de chat
let socket = new Socket("/socket", {params: {token: userToken}})
socket.connect()

let channel = socket.channel("event_chat:123", {})
channel.join()
  .receive("ok", resp => console.log("Joined successfully", resp))
  .receive("error", resp => console.log("Unable to join", resp))

// Enviar mensagem
channel.push("new_message", {message: "Olá!", is_question: false})

// Receber mensagens
channel.on("new_message", payload => {
  console.log(`${payload.user_name}: ${payload.message}`)
})
```

```

### Checklist de Features

- [x] Autenticação com 3 papéis (admin, speaker, student)
- [x] Autorização RBAC
- [x] CRUD de eventos com validações
- [x] Sistema de inscrições com controle de vagas
- [x] Chat em tempo real (Phoenix Channels)
- [x] Notificações em tempo real
- [x] Geração de certificados PDF
- [x] Verificação de certificados
- [x] Dashboards com estatísticas
- [x] Relatórios por curso/departamento
- [x] Exportação CSV
- [x] Full-text search (PostgreSQL)
- [x] Nginx como proxy reverso
- [x] SSL/HTTPS
- [x] WebSocket support
- [x] Rate limiting
- [x] Testes automatizados

## Contribuição

1. Fork o projeto
2. Crie uma branch (`git checkout -b feature/nova-feature`)
3. Commit suas mudanças (`git commit -m 'Adiciona nova feature'`)
4. Push para a branch (`git push origin feature/nova-feature`)
5. Abra um Pull Request

## Licença

MIT License - veja [LICENSE](LICENSE) para detalhes.

## Autores

- **Professor(a)**: Maria Luisa Ghizoni Gonzalez, Roque Mendes Prado Trindade
- **Disciplina**: Paradigmas de Linguagens de Programação (PLP)
- **Grupo**: [Adicionar nomes dos integrantes]

```
