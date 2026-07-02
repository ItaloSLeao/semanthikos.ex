defmodule EventManager.Services do
  @moduledoc """
  Gerente de Apoio (Serviços Secundários).

  Responsável por gerenciar funcionalidades secundárias ou de suporte ao sistema, como:
  - Chats ao vivo (armazenamento de histórico, emissão de mensagens).
  - Geração de certificados.
  - Extração de relatórios analíticos do sistema.
  """
  import Ecto.Query
  alias EventManager.Repo
  alias EventManager.Schemas.{ChatMessage, Certificate, Event, Registration, User}

  ## --- CHAT & NOTIFICATIONS ---

  def create_chat_message(attrs) do
    %ChatMessage{} |> ChatMessage.changeset(attrs) |> Repo.insert() |> broadcast()
  end

  def list_event_chat_messages(event_id, opts \\ []) do
    limit = Keyword.get(opts, :limit, 100)

    from(m in ChatMessage,
      where: m.event_id == ^event_id,
      preload: [:user],
      order_by: [asc: m.sent_at],
      limit: ^limit
    )
    |> Repo.all()
  end

  def mark_question_answered(message_id) do
    Repo.get!(ChatMessage, message_id)
    |> ChatMessage.answer_changeset()
    |> Repo.update()
    |> broadcast()
  end

  defp broadcast({:ok, msg}) do
    msg = Repo.preload(msg, :user)

    EventManagerWeb.Endpoint.broadcast("event_chat:#{msg.event_id}", "new_message", %{
      id: msg.id,
      user_id: msg.user_id,
      message: msg.message,
      user_name: msg.user && msg.user.name,
      avatar_path: msg.user && msg.user.avatar_path,
      sent_at: msg.sent_at,
      is_question: msg.is_question,
      is_answered: msg.is_answered
    })

    {:ok, msg}
  end

  defp broadcast(error), do: error

  def broadcast_event_notification(event_id, type, data),
    do: EventManagerWeb.Endpoint.broadcast("event_notifications:#{event_id}", type, data)

  def broadcast_capacity_warning(event_id, remaining_seats),
    do:
      broadcast_event_notification(event_id, "capacity_warning", %{
        remaining_seats: remaining_seats
      })

  def broadcast_event_reminder(event_id, minutes_until),
    do: broadcast_event_notification(event_id, "event_reminder", %{minutes_until: minutes_until})

  ## --- CERTIFICATES ---

  def generate_certificate(user_id, event_id, type \\ :participation) do
    %Certificate{}
    |> Certificate.changeset(%{user_id: user_id, event_id: event_id, certificate_type: type})
    |> Repo.insert()
    |> then(&generate_pdf_data/1)
  end

  def generate_event_certificates(event_id) do
    EventManager.Core.list_event_registrations(event_id)
    |> Enum.filter(& &1.attended)
    |> Enum.map(&generate_certificate(&1.user_id, event_id, :participation))
    |> Enum.filter(&match?({:ok, _}, &1))
    |> length()
  end

  defp generate_pdf_data({:ok, cert}) do
    user = Repo.get!(User, cert.user_id)
    event = Repo.get!(Event, cert.event_id) |> Repo.preload(:speaker)

    cert
    |> Ecto.Changeset.change(pdf_data: build_certificate_pdf(user, event, cert))
    |> Repo.update()
  end

  defp generate_pdf_data(error), do: error

  def build_certificate_pdf(user, event, cert) do
    """
    <!DOCTYPE html>
    <html lang="pt-BR">
    <head>
      <meta charset="utf-8">
      <style>
        @import url('https://fonts.googleapis.com/css2?family=Cinzel:wght@400;600;700&family=EB+Garamond:ital,wght@0,400;0,500;1,400;1,500&family=Cormorant+Garamond:ital,wght@1,500;1,600&family=Raleway:wght@300;400;500;600;700&display=swap');

        @page { size: A4 landscape; margin: 0; }

        *, *::before, *::after { box-sizing: border-box; }

        body {
          margin: 0; padding: 0;
          -webkit-print-color-adjust: exact !important;
          print-color-adjust: exact !important;
          background-color: #b8ae9e;
          display: flex;
          justify-content: center;
          align-items: center;
          min-height: 100vh;
        }

        /* ── Wrapper / Pergaminho ── */
        .certificate-wrapper {
          position: relative;
          overflow: hidden;
          background-color: #F8F2E4;
          background-image:
            radial-gradient(ellipse 75% 55% at 50% 48%, rgba(184,149,42,0.10) 0%, transparent 68%),
            repeating-linear-gradient(
              0deg,
              transparent 0px, transparent 29px,
              rgba(12,31,60,0.018) 29px, rgba(12,31,60,0.018) 30px
            ),
            repeating-linear-gradient(
              90deg,
              transparent 0px, transparent 29px,
              rgba(12,31,60,0.018) 29px, rgba(12,31,60,0.018) 30px
            );
        }

        @media screen {
          .certificate-wrapper {
            width: 297mm; height: 210mm;
            padding: 8mm;
            box-shadow: 0 30px 80px rgba(0,0,0,0.5), 0 6px 20px rgba(0,0,0,0.2);
            margin: 20px;
          }
        }

        @media print {
          body { background-color: #F8F2E4; display: block; }
          .certificate-wrapper {
            width: 100vw; height: 100vh;
            padding: 8mm;
            margin: 0;
            box-shadow: none;
          }
        }

        /* ── Sistema de bordas triplas ── */
        .b-outer {
          width: 100%; height: 100%;
          border: 9px solid #0C1F3C;
          padding: 3px;
        }

        .b-gold {
          width: 100%; height: 100%;
          border: 2px solid #B8952A;
          padding: 2px;
        }

        .b-inner {
          width: 100%; height: 100%;
          border: 1px solid rgba(12, 31, 60, 0.30);
          display: flex;
          flex-direction: column;
          align-items: center;
          justify-content: space-between;
          padding: 14px 52px 11px;
          position: relative;
        }

        /* ── Ornamentos de canto (CSS puro) ── */
        .corner {
          position: absolute;
          width: 56px; height: 56px;
          z-index: 6;
        }

        /* L externo em azul naval */
        .corner-tl { top: -2px; left: -2px;
          border-top: 6px solid #0C1F3C; border-left: 6px solid #0C1F3C; }
        .corner-tr { top: -2px; right: -2px;
          border-top: 6px solid #0C1F3C; border-right: 6px solid #0C1F3C; }
        .corner-bl { bottom: -2px; left: -2px;
          border-bottom: 6px solid #0C1F3C; border-left: 6px solid #0C1F3C; }
        .corner-br { bottom: -2px; right: -2px;
          border-bottom: 6px solid #0C1F3C; border-right: 6px solid #0C1F3C; }

        /* L interno dourado (accent) */
        .corner::before {
          content: '';
          position: absolute;
          width: 38px; height: 38px;
        }
        .corner-tl::before { top: 10px; left: 10px;
          border-top: 1.5px solid #B8952A; border-left: 1.5px solid #B8952A; }
        .corner-tr::before { top: 10px; right: 10px;
          border-top: 1.5px solid #B8952A; border-right: 1.5px solid #B8952A; }
        .corner-bl::before { bottom: 10px; left: 10px;
          border-bottom: 1.5px solid #B8952A; border-left: 1.5px solid #B8952A; }
        .corner-br::before { bottom: 10px; right: 10px;
          border-bottom: 1.5px solid #B8952A; border-right: 1.5px solid #B8952A; }

        /* Losango dourado no vértice do L */
        .corner::after {
          content: '';
          position: absolute;
          width: 10px; height: 10px;
          background: #B8952A;
          transform: rotate(45deg);
        }
        .corner-tl::after { top: -2px;    left: -2px; }
        .corner-tr::after { top: -2px;    right: -2px; }
        .corner-bl::after { bottom: -2px; left: -2px; }
        .corner-br::after { bottom: -2px; right: -2px; }

        /* ── Cabeçalho ── */
        .cert-header {
          text-align: center;
          z-index: 2;
          line-height: 1;
        }

        .issuer-label {
          font-family: 'Raleway', sans-serif;
          font-size: 9px;
          color: #B8952A;
          letter-spacing: 5px;
          text-transform: uppercase;
          font-weight: 600;
          display: block;
          margin-bottom: 5px;
        }

        .cert-main-title {
          font-family: 'Cinzel', serif;
          font-size: 46px;
          color: #0C1F3C;
          letter-spacing: 16px;
          text-transform: uppercase;
          font-weight: 700;
          line-height: 1;
          display: block;
          text-shadow: 0 1px 0 rgba(184,149,42,0.38);
        }

        .cert-type {
          font-family: 'Raleway', sans-serif;
          font-size: 10.5px;
          color: #B8952A;
          letter-spacing: 7px;
          text-transform: uppercase;
          font-weight: 600;
          display: block;
          margin-top: 5px;
        }

        /* ── Divisor ornamental ── */
        .divider {
          width: 94%;
          display: flex;
          align-items: center;
          gap: 14px;
          z-index: 2;
          flex-shrink: 0;
        }

        .div-line {
          flex: 1;
          height: 1px;
          background: linear-gradient(90deg, transparent 0%, #B8952A 35%, #B8952A 65%, transparent 100%);
        }

        .div-motif {
          display: flex;
          align-items: center;
          gap: 5px;
          flex-shrink: 0;
        }

        .d-sm {
          display: block;
          width: 5px; height: 5px;
          background: #B8952A;
          transform: rotate(45deg);
          flex-shrink: 0;
        }

        .d-md {
          display: block;
          width: 8px; height: 8px;
          background: #B8952A;
          transform: rotate(45deg);
          flex-shrink: 0;
        }

        /* ── Corpo do certificado ── */
        .cert-body {
          font-family: 'EB Garamond', serif;
          font-size: 17.5px;
          line-height: 1.48;
          color: #252530;
          text-align: center;
          z-index: 2;
          max-width: 88%;
        }

        .certify-phrase {
          font-style: italic;
          font-size: 16px;
          color: #6a6a7a;
          display: block;
          margin-bottom: 3px;
        }

        /* Elemento-assinatura: Cormorant Garamond itálico para o nome */
        .recipient {
          font-family: 'Cormorant Garamond', serif;
          font-style: italic;
          font-size: 37px;
          color: #0C1F3C;
          font-weight: 600;
          display: inline-block;
          margin: 4px 0;
          padding-bottom: 5px;
          border-bottom: 1px solid #B8952A;
          letter-spacing: 0.5px;
        }

        .participation {
          display: block;
          margin: 3px 0;
        }

        .event-name {
          font-family: 'Cinzel', serif;
          font-size: 14.5px;
          color: #0C1F3C;
          font-weight: 600;
          letter-spacing: 1.5px;
          text-transform: uppercase;
          display: block;
          margin: 2px 0;
        }

        .event-details {
          font-size: 16.5px;
          display: block;
          margin: 2px 0;
          color: #38384a;
        }

        .speaker {
          font-style: italic;
          font-size: 15px;
          color: #7a7a8a;
          display: block;
          margin-top: 3px;
        }

        /* ── Rodapé ── */
        .cert-footer {
          width: 100%;
          display: flex;
          justify-content: space-between;
          align-items: flex-end;
          z-index: 2;
          position: relative;
        }

        .cert-meta {
          font-family: 'Raleway', sans-serif;
          font-size: 8px;
          color: #9a9aaa;
          line-height: 2;
          text-transform: uppercase;
          letter-spacing: 1.3px;
          border-left: 2px solid #B8952A;
          padding-left: 9px;
        }

        .cert-meta strong {
          display: block;
          color: #606072;
          font-size: 8.5px;
          font-weight: 600;
          margin-bottom: 1px;
        }

        .sig-box {
          text-align: center;
          width: 200px;
        }

        .sig-line {
          border-top: 1px solid #0C1F3C;
          padding-top: 6px;
        }

        .sig-name {
          font-family: 'Cinzel', serif;
          font-size: 12.5px;
          color: #0C1F3C;
          font-weight: 600;
          letter-spacing: 2px;
          text-transform: uppercase;
          display: block;
        }

        .sig-role {
          font-family: 'Raleway', sans-serif;
          font-size: 8px;
          color: #9a9aaa;
          text-transform: uppercase;
          letter-spacing: 2px;
          display: block;
          margin-top: 2px;
        }

        /* ── Selo marca d'água ── */
        .seal-watermark {
          position: absolute;
          bottom: 6px;
          left: 50%;
          transform: translateX(-50%);
          width: 155px; height: 155px;
          opacity: 0.11;
          z-index: 1;
          pointer-events: none;
        }
      </style>
    </head>
    <body>
      <div class="certificate-wrapper">
        <div class="b-outer">
          <div class="b-gold">
            <div class="b-inner">

              <!-- Ornamentos de canto -->
              <div class="corner corner-tl"></div>
              <div class="corner corner-tr"></div>
              <div class="corner corner-bl"></div>
              <div class="corner corner-br"></div>

              <!-- Cabeçalho -->
              <div class="cert-header">
                <!-- Brasão institucional minimalista -->
                <svg width="38" height="38" viewBox="0 0 38 38" fill="none"
                     xmlns="http://www.w3.org/2000/svg"
                     style="display:block; margin:0 auto 5px; opacity:0.92;">
                  <path d="M4 4 H34 V24 Q19 36 4 24 Z"
                        fill="none" stroke="#B8952A" stroke-width="1.6"/>
                  <path d="M7.5 7.5 H30.5 V23 Q19 32 7.5 23 Z"
                        fill="none" stroke="#0C1F3C" stroke-width="0.7"/>
                  <!-- Detalhe de lauréis esquemáticos -->
                  <path d="M8.5 20 Q10 16 13 14.5 Q11.5 17.5 9.5 20 Z" fill="#0C1F3C"/>
                  <path d="M29.5 20 Q28 16 25 14.5 Q26.5 17.5 28.5 20 Z" fill="#0C1F3C"/>
                  <!-- Monograma S -->
                  <text x="19" y="24" text-anchor="middle"
                        font-family="Cinzel, serif" font-size="13"
                        fill="#0C1F3C" font-weight="700">S</text>
                </svg>

                <span class="issuer-label">Semantikos · Plataforma Acadêmica</span>
                <span class="cert-main-title">Certificado</span>
                <!-- cert_type retorna: "Participação", "Apresentação" ou "Organização" -->
                <span class="cert-type">de #{cert_type(cert.certificate_type)}</span>
              </div>

              <!-- Divisor superior -->
              <div class="divider">
                <div class="div-line"></div>
                <div class="div-motif">
                  <span class="d-sm"></span>
                  <span class="d-md"></span>
                  <span class="d-sm"></span>
                </div>
                <div class="div-line"></div>
              </div>

              <!-- Corpo -->
              <div class="cert-body">
                <span class="certify-phrase">Certificamos que</span>
                <span class="recipient">#{user.name}</span>
                <span class="participation">participou com êxito do evento acadêmico</span>
                <span class="event-name">#{event.title}</span>
                <span class="event-details">
                  realizado em <strong>#{fmt_date(event.date)}</strong>,
                  com carga horária oficial de <strong>#{div(event.duration_minutes, 60)} hora(s)</strong>,<br/>
                  na modalidade #{if event.is_online, do: "online", else: "presencial"} #{if !event.is_online, do: "em " <> event.location, else: ""}.
                </span>
                <span class="speaker">#{if event.speaker, do: "Ministrado por #{event.speaker.name}", else: ""}</span>
              </div>

              <!-- Divisor inferior -->
              <div class="divider">
                <div class="div-line"></div>
                <div class="div-motif">
                  <span class="d-sm"></span>
                  <span class="d-md"></span>
                  <span class="d-sm"></span>
                </div>
                <div class="div-line"></div>
              </div>

              <!-- Rodapé -->
              <div class="cert-footer">
                <div class="cert-meta">
                  <strong>Autenticidade e Verificação</strong>
                  Documento Nº: #{cert.certificate_number}<br/>
                  Data de Emissão: #{fmt_date(cert.generated_at)}
                </div>

                <div class="sig-box">
                  <div class="sig-line"></div>
                  <span class="sig-name">Semantikos</span>
                  <span class="sig-role">Coordenação Acadêmica</span>
                </div>
              </div>

              <!-- Selo marca d'água com texto circular -->
              <svg class="seal-watermark" viewBox="0 0 200 200"
                   fill="none" xmlns="http://www.w3.org/2000/svg">
                <defs>
                  <path id="cert-ring-path"
                    d="M100,100 m-72,0 a72,72 0 1,1 144,0 a72,72 0 1,1 -144,0"/>
                </defs>
                <!-- Anéis concêntricos -->
                <circle cx="100" cy="100" r="94" stroke="#B8952A" stroke-width="2.5" fill="none"/>
                <circle cx="100" cy="100" r="88" stroke="#0C1F3C" stroke-width="0.6" fill="none"/>
                <circle cx="100" cy="100" r="79" stroke="#B8952A" stroke-width="1"
                        stroke-dasharray="4 3" fill="none"/>
                <circle cx="100" cy="100" r="55" stroke="#0C1F3C" stroke-width="1.5" fill="none"/>
                <circle cx="100" cy="100" r="49" stroke="#B8952A" stroke-width="0.7" fill="none"/>
                <!-- Estrela central -->
                <path d="M100 63 L107 84 L129 84 L113 97 L119 118 L100 105 L81 118 L87 97 L71 84 L93 84 Z"
                      fill="#0C1F3C"/>
                <!-- Texto no anel -->
                <text font-family="Cinzel, serif" font-size="9" fill="#0C1F3C" letter-spacing="2">
                  <textPath href="#cert-ring-path" startOffset="4%">
                    · SEMANTIKOS · COORDENAÇÃO ACADÊMICA · CERTIFICADO OFICIAL ·
                  </textPath>
                </text>
              </svg>

            </div>
          </div>
        </div>
      </div>
    </body>
    </html>
    """
  end

  defp cert_type(:participation), do: "Participação"
  defp cert_type(:speaker), do: "Apresentação"
  defp cert_type(:organizer), do: "Organização"
  defp fmt_date(dt), do: Calendar.strftime(dt, "%d/%m/%Y às %H:%M")

  def get_certificate!(id), do: Repo.get!(Certificate, id)

  def get_certificate_by_number(number),
    do: Repo.get_by(Certificate, certificate_number: number) |> Repo.preload([:user, :event])

  def list_user_certificates(user_id) do
    from(c in Certificate,
      where: c.user_id == ^user_id,
      preload: [:event],
      order_by: [desc: c.generated_at]
    )
    |> Repo.all()
  end

  def list_event_certificates(event_id) do
    from(c in Certificate,
      where: c.event_id == ^event_id,
      preload: [:user],
      order_by: [asc: c.generated_at]
    )
    |> Repo.all()
  end

  def verify_certificate(number) do
    case get_certificate_by_number(number) do
      nil ->
        {:error, :not_found}

      cert ->
        {:ok,
         %{
           certificate_number: cert.certificate_number,
           user_name: cert.user.name,
           event_title: cert.event.title,
           event_date: cert.event.date,
           generated_at: cert.generated_at,
           verified: cert.verified
         }}
    end
  end

  ## --- REPORTS ---

  def get_system_stats do
    %{
      total_events: Repo.aggregate(Event, :count, :id),
      total_users: Repo.aggregate(User, :count, :id),
      total_registrations: Repo.aggregate(Registration, :count, :id),
      upcoming_events:
        from(e in Event, where: e.date > ^DateTime.utc_now() and e.status == :published)
        |> Repo.aggregate(:count, :id),
      completed_events:
        from(e in Event, where: e.status == :completed) |> Repo.aggregate(:count, :id)
    }
  end

  def get_occupancy_report(opts \\ []) do
    from(e in Event,
      left_join: r in Registration,
      on: r.event_id == e.id,
      where: e.status in [:published, :completed],
      group_by: e.id,
      select: %{
        event_id: e.id,
        title: e.title,
        date: e.date,
        max_seats: e.max_seats,
        registrations: count(r.id),
        occupancy_rate:
          fragment(
            "ROUND(CAST(COUNT(?) AS NUMERIC) / CAST(NULLIF(?, 0) AS NUMERIC) * 100, 2)",
            r.id,
            e.max_seats
          ),
        remaining_seats: e.max_seats - count(r.id)
      },
      order_by: [desc: e.date]
    )
    |> maybe_limit(opts[:limit])
    |> Repo.all()
  end

  def get_participation_by_course(_opts \\ []) do
    from(u in User,
      left_join: r in Registration,
      on: r.user_id == u.id,
      where: not is_nil(u.course),
      group_by: u.course,
      select: %{
        course: u.course,
        total_registrations: count(r.id),
        total_attended: fragment("COUNT(CASE WHEN ? THEN 1 END)", r.attended)
      },
      order_by: [desc: count(r.id)]
    )
    |> Repo.all()
  end

  def get_participation_by_department do
    from(u in User,
      left_join: r in Registration,
      on: r.user_id == u.id,
      where: not is_nil(u.department),
      group_by: u.department,
      select: %{
        department: u.department,
        total_registrations: count(r.id),
        total_attended: fragment("COUNT(CASE WHEN ? THEN 1 END)", r.attended)
      },
      order_by: [desc: count(r.id)]
    )
    |> Repo.all()
  end

  def get_monthly_stats(year \\ DateTime.utc_now().year) do
    from(e in Event,
      where: fragment("EXTRACT(YEAR FROM ?) = ?", e.date, ^year),
      group_by: fragment("EXTRACT(MONTH FROM date)"),
      select: %{
        month: fragment("EXTRACT(MONTH FROM date)"),
        total_events: count(e.id),
        total_seats: sum(e.max_seats)
      },
      order_by: [asc: fragment("EXTRACT(MONTH FROM date)")]
    )
    |> Repo.all()
  end

  def export_registrations_csv(event_id) do
    regs =
      from(r in Registration,
        where: r.event_id == ^event_id,
        preload: [:user],
        order_by: [asc: r.registered_at]
      )
      |> Repo.all()

    headers = ["Nome", "Email", "Curso", "Departamento", "Data Registro", "Presença"]

    rows =
      Enum.map(regs, fn r ->
        [
          r.user.name,
          r.user.email,
          r.user.course || "N/A",
          r.user.department || "N/A",
          Calendar.strftime(r.registered_at, "%d/%m/%Y %H:%M"),
          if(r.attended, do: "Sim", else: "Não")
        ]
      end)

    [headers | rows] |> CSV.encode() |> Enum.to_list() |> IO.iodata_to_binary()
  end

  def export_events_csv(opts \\ []) do
    events = EventManager.Core.list_events(opts)
    headers = ["Título", "Data", "Local", "Vagas", "Inscritos", "Ocupação (%)", "Status"]

    rows =
      Enum.map(events, fn e ->
        regs = length(e.registrations || [])

        [
          e.title,
          Calendar.strftime(e.date, "%d/%m/%Y %H:%M"),
          e.location,
          e.max_seats,
          regs,
          Float.round(regs / max(e.max_seats, 1) * 100, 2),
          Atom.to_string(e.status)
        ]
      end)

    [headers | rows] |> CSV.encode() |> Enum.to_list() |> IO.iodata_to_binary()
  end

  def get_speaker_stats(speaker_id) do
    events =
      from(e in Event, where: e.speaker_id == ^speaker_id, preload: [:registrations])
      |> Repo.all()

    total_events = length(events)
    total_regs = events |> Enum.map(&length(&1.registrations)) |> Enum.sum()

    %{
      speaker_id: speaker_id,
      total_events: total_events,
      total_registrations: total_regs,
      average_registrations: if(total_events > 0, do: total_regs / total_events, else: 0)
    }
  end

  defp maybe_limit(query, nil), do: query
  defp maybe_limit(query, limit), do: limit(query, ^limit)
end
