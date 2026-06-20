defmodule EventManager.Services do
  @moduledoc "Services context consolidating Notifications, Certificates, and Reports logic."
  import Ecto.Query
  alias EventManager.Repo
  alias EventManager.Schemas.{ChatMessage, Certificate, Event, Registration, User}

  ## --- CHAT & NOTIFICATIONS ---

  def create_chat_message(attrs) do
    %ChatMessage{} |> ChatMessage.changeset(attrs) |> Repo.insert() |> broadcast()
  end

  def list_event_chat_messages(event_id, opts \\ []) do
    limit = Keyword.get(opts, :limit, 100)
    from(m in ChatMessage, where: m.event_id == ^event_id, preload: [:user],
         order_by: [asc: m.sent_at], limit: ^limit) |> Repo.all()
  end

  def mark_question_answered(message_id) do
    Repo.get!(ChatMessage, message_id) |> ChatMessage.answer_changeset() |> Repo.update() |> broadcast()
  end

  defp broadcast({:ok, msg}) do
    msg = Repo.preload(msg, :user)
    EventManagerWeb.Endpoint.broadcast("event_chat:#{msg.event_id}", "new_message", %{
      id: msg.id, message: msg.message, user_name: msg.user && msg.user.name,
      sent_at: msg.sent_at, is_question: msg.is_question, is_answered: msg.is_answered
    })
    {:ok, msg}
  end
  defp broadcast(error), do: error

  def broadcast_event_notification(event_id, type, data),
    do: EventManagerWeb.Endpoint.broadcast("event_notifications:#{event_id}", type, data)

  def broadcast_capacity_warning(event_id, remaining_seats),
    do: broadcast_event_notification(event_id, "capacity_warning", %{remaining_seats: remaining_seats})

  def broadcast_event_reminder(event_id, minutes_until),
    do: broadcast_event_notification(event_id, "event_reminder", %{minutes_until: minutes_until})

  ## --- CERTIFICATES ---

  def generate_certificate(user_id, event_id, type \\ :participation) do
    %Certificate{} |> Certificate.changeset(%{user_id: user_id, event_id: event_id, certificate_type: type})
    |> Repo.insert() |> then(&generate_pdf_data/1)
  end

  def generate_event_certificates(event_id) do
    EventManager.Core.list_event_registrations(event_id)
    |> Enum.filter(& &1.attended)
    |> Enum.map(&generate_certificate(&1.user_id, event_id, :participation))
    |> Enum.filter(&match?({:ok, _}, &1)) |> length()
  end

  defp generate_pdf_data({:ok, cert}) do
    user = Repo.get!(User, cert.user_id)
    event = Repo.get!(Event, cert.event_id) |> Repo.preload(:speaker)
    cert |> Ecto.Changeset.change(pdf_data: build_certificate_pdf(user, event, cert)) |> Repo.update()
  end
  defp generate_pdf_data(error), do: error

  def build_certificate_pdf(user, event, cert) do
    """
    <!DOCTYPE html><html><head><meta charset="utf-8">
    <style>
      @import url('https://fonts.googleapis.com/css2?family=Cinzel:wght@500;700;900&family=Playfair+Display:ital,wght@0,400;0,600;1,400&family=Montserrat:wght@400;500;600&display=swap');
      @page { size: A4 landscape; margin: 0; }
      body {
        margin: 0; padding: 0;
        -webkit-print-color-adjust: exact !important;
        print-color-adjust: exact !important;
        background-color: #e2e8f0;
        display: flex;
        justify-content: center;
        align-items: center;
        min-height: 100vh;
      }
      .certificate-wrapper {
        box-sizing: border-box;
        background-color: #ffffff;
        background-image: 
          radial-gradient(circle at center, rgba(212, 175, 55, 0.08) 0%, transparent 60%),
          repeating-linear-gradient(45deg, rgba(26, 54, 93, 0.03) 0px, rgba(26, 54, 93, 0.03) 1px, transparent 1px, transparent 10px),
          repeating-linear-gradient(-45deg, rgba(212, 175, 55, 0.04) 0px, rgba(212, 175, 55, 0.04) 1px, transparent 1px, transparent 10px);
        position: relative;
        overflow: hidden;
      }
      @media screen {
        .certificate-wrapper {
          width: 297mm; height: 210mm;
          padding: 12mm;
          box-shadow: 0 20px 50px rgba(0,0,0,0.3);
          margin: 20px;
        }
      }
      @media print {
        body { background-color: #ffffff; display: block; }
        .certificate-wrapper {
          width: 100vw; height: 100vh;
          padding: 10mm;
          margin: 0;
          box-shadow: none;
        }
      }

      .certificate-border {
        position: relative;
        width: 100%; height: 100%;
        border: 12px solid #1a365d;
        box-sizing: border-box;
        padding: 10px;
      }
      .certificate-inner-border {
        width: 100%; height: 100%;
        border: 4px solid #d4af37;
        box-sizing: border-box;
        padding: 30px 50px;
        display: flex;
        flex-direction: column;
        justify-content: space-between;
        align-items: center;
        background: rgba(255, 255, 255, 0.92);
        box-shadow: inset 0 0 60px rgba(212, 175, 55, 0.15);
        position: relative;
      }

      .corner { position: absolute; width: 45px; height: 45px; border: 5px solid #d4af37; }
      .corner-tl { top: -5px; left: -5px; border-right: none; border-bottom: none; }
      .corner-tr { top: -5px; right: -5px; border-left: none; border-bottom: none; }
      .corner-bl { bottom: -5px; left: -5px; border-right: none; border-top: none; }
      .corner-br { bottom: -5px; right: -5px; border-left: none; border-top: none; }

      .header {
        font-family: 'Cinzel', serif;
        font-size: 50px;
        color: #1a365d;
        letter-spacing: 14px;
        margin-top: 10px;
        margin-bottom: 0px;
        text-transform: uppercase;
        font-weight: 900;
        text-shadow: 1px 1px 0 rgba(212, 175, 55, 0.5);
      }
      .subtitle {
        font-family: 'Montserrat', sans-serif;
        font-size: 16px;
        color: #d4af37;
        letter-spacing: 8px;
        text-transform: uppercase;
        margin-bottom: 25px;
        font-weight: 700;
      }
      .content {
        font-family: 'Playfair Display', serif;
        font-size: 20px;
        line-height: 1.6;
        color: #2d3748;
        text-align: center;
        max-width: 85%;
        z-index: 2;
      }
      .recipient {
        font-family: 'Cinzel', serif;
        font-size: 40px;
        color: #1a365d;
        font-weight: 700;
        margin: 15px 0;
        border-bottom: 2px solid #d4af37;
        padding-bottom: 4px;
        display: inline-block;
      }
      .event-title {
        font-family: 'Montserrat', sans-serif;
        font-size: 24px;
        color: #1a365d;
        font-weight: 700;
        margin: 10px 0;
        text-transform: uppercase;
      }
      .footer-grid {
        width: 100%;
        display: flex;
        justify-content: space-between;
        align-items: flex-end;
        margin-top: 20px;
        font-family: 'Montserrat', sans-serif;
        z-index: 2;
      }
      .signature-box { text-align: center; width: 280px; }
      .signature-line { border-top: 1px solid #1a365d; margin-bottom: 8px; padding-top: 8px; }
      .signature-box h4 { margin: 0; font-size: 16px; color: #1a365d; font-weight: 700; text-transform: uppercase; letter-spacing: 1px; }
      .signature-box p { margin: 4px 0 0; font-size: 11px; color: #718096; text-transform: uppercase; letter-spacing: 1px; }
      
      .cert-meta {
        text-align: left; font-size: 10px; color: #718096; line-height: 1.6;
        text-transform: uppercase; letter-spacing: 1px;
      }
      .badge-container {
        width: 180px; height: 180px; position: absolute; bottom: 15px; left: 50%; transform: translateX(-50%); opacity: 0.15; z-index: 1;
      }
    </style>
    </head>
    <body>
      <div class="certificate-wrapper">
        <div class="certificate-border">
          <div class="certificate-inner-border">
            <div class="corner corner-tl"></div>
            <div class="corner corner-tr"></div>
            <div class="corner corner-bl"></div>
            <div class="corner corner-br"></div>
            
            <div style="text-align: center; z-index: 2;">
              <h1 class="header">Certificado</h1>
              <div class="subtitle">de #{cert_type(cert.certificate_type)}</div>
            </div>
            
            <div class="content">
              <p style="margin:0; font-style: italic;">Certificamos orgulhosamente que</p>
              <div class="recipient">#{user.name}</div>
              <p style="margin:0;">participou com êxito do evento acadêmico</p>
              <div class="event-title">#{event.title}</div>
              <p style="margin:10px 0 0;">
                realizado em <strong>#{fmt_date(event.date)}</strong>, 
                com carga horária oficial de <strong>#{div(event.duration_minutes, 60)} hora(s)</strong>,<br/>
                na modalidade #{if event.is_online, do: "online", else: "presencial"} #{if !event.is_online, do: "em " <> event.location, else: ""}.
              </p>
              <p style="margin:10px 0 0; font-size:16px; font-style:italic;">#{if event.speaker, do: "Ministrado por #{event.speaker.name}", else: ""}</p>
            </div>

            <div class="footer-grid">
              <div class="cert-meta">
                <strong>Autenticidade e Verificação:</strong><br/>
                Documento Nº: #{cert.certificate_number}<br/>
                Data de Emissão: #{fmt_date(cert.generated_at)}
              </div>
              
              <div class="signature-box">
                <div class="signature-line"></div>
                <h4>Semanthikos</h4>
                <p>Coordenação Acadêmica</p>
              </div>
            </div>

            <div class="badge-container">
              <svg viewBox="0 0 100 100" fill="none" xmlns="http://www.w3.org/2000/svg">
                <circle cx="50" cy="50" r="45" fill="#d4af37" fill-opacity="0.3" stroke="#d4af37" stroke-width="2" stroke-dasharray="4 4"/>
                <circle cx="50" cy="50" r="35" fill="none" stroke="#1a365d" stroke-width="2"/>
                <path d="M50 20 L55 35 L70 40 L55 45 L50 60 L45 45 L30 40 L45 35 Z" fill="#1a365d"/>
              </svg>
            </div>
          </div>
        </div>
      </div>
      <script>window.onload = function() { setTimeout(function() { window.print(); }, 500); }</script>
    </body>
    </html>
    """
  end

  defp cert_type(:participation), do: "Participação"
  defp cert_type(:speaker), do: "Apresentação"
  defp cert_type(:organizer), do: "Organização"
  defp fmt_date(dt), do: Calendar.strftime(dt, "%d/%m/%Y às %H:%M")

  def get_certificate!(id), do: Repo.get!(Certificate, id)
  def get_certificate_by_number(number), do: Repo.get_by(Certificate, certificate_number: number) |> Repo.preload([:user, :event])

  def list_user_certificates(user_id) do
    from(c in Certificate, where: c.user_id == ^user_id, preload: [:event], order_by: [desc: c.generated_at]) |> Repo.all()
  end

  def list_event_certificates(event_id) do
    from(c in Certificate, where: c.event_id == ^event_id, preload: [:user], order_by: [asc: c.generated_at]) |> Repo.all()
  end

  def verify_certificate(number) do
    case get_certificate_by_number(number) do
      nil -> {:error, :not_found}
      cert -> {:ok, %{certificate_number: cert.certificate_number, user_name: cert.user.name, event_title: cert.event.title,
                      event_date: cert.event.date, generated_at: cert.generated_at, verified: cert.verified}}
    end
  end

  ## --- REPORTS ---

  def get_system_stats do
    %{
      total_events: Repo.aggregate(Event, :count, :id),
      total_users: Repo.aggregate(User, :count, :id),
      total_registrations: Repo.aggregate(Registration, :count, :id),
      upcoming_events: from(e in Event, where: e.date > ^DateTime.utc_now() and e.status == :published) |> Repo.aggregate(:count, :id),
      completed_events: from(e in Event, where: e.status == :completed) |> Repo.aggregate(:count, :id)
    }
  end

  def get_occupancy_report(opts \\ []) do
    from(e in Event,
      left_join: r in Registration, on: r.event_id == e.id,
      where: e.status in [:published, :completed],
      group_by: e.id,
      select: %{
        event_id: e.id,
        title: e.title,
        date: e.date,
        max_seats: e.max_seats,
        registrations: count(r.id),
        occupancy_rate: fragment("ROUND(CAST(COUNT(?) AS NUMERIC) / CAST(NULLIF(?, 0) AS NUMERIC) * 100, 2)", r.id, e.max_seats),
        remaining_seats: e.max_seats - count(r.id)
      },
      order_by: [desc: e.date]
    )
    |> maybe_limit(opts[:limit])
    |> Repo.all()
  end

  def get_participation_by_course(_opts \\ []) do
    from(u in User, left_join: r in Registration, on: r.user_id == u.id, where: not is_nil(u.course),
      group_by: u.course,
      select: %{course: u.course, total_registrations: count(r.id),
                total_attended: fragment("COUNT(CASE WHEN ? THEN 1 END)", r.attended)},
      order_by: [desc: count(r.id)]) |> Repo.all()
  end

  def get_participation_by_department do
    from(u in User, left_join: r in Registration, on: r.user_id == u.id, where: not is_nil(u.department),
      group_by: u.department,
      select: %{department: u.department, total_registrations: count(r.id),
                total_attended: fragment("COUNT(CASE WHEN ? THEN 1 END)", r.attended)},
      order_by: [desc: count(r.id)]) |> Repo.all()
  end

  def get_monthly_stats(year \\ DateTime.utc_now().year) do
    from(e in Event, where: fragment("EXTRACT(YEAR FROM ?) = ?", e.date, ^year),
      group_by: fragment("EXTRACT(MONTH FROM date)"),
      select: %{month: fragment("EXTRACT(MONTH FROM date)"), total_events: count(e.id), total_seats: sum(e.max_seats)},
      order_by: [asc: fragment("EXTRACT(MONTH FROM date)")]) |> Repo.all()
  end

  def export_registrations_csv(event_id) do
    regs = from(r in Registration, where: r.event_id == ^event_id, preload: [:user], order_by: [asc: r.registered_at]) |> Repo.all()
    headers = ["Nome", "Email", "Curso", "Departamento", "Data Registro", "Presença"]
    rows = Enum.map(regs, fn r ->
      [r.user.name, r.user.email, r.user.course || "N/A", r.user.department || "N/A",
       Calendar.strftime(r.registered_at, "%d/%m/%Y %H:%M"), if(r.attended, do: "Sim", else: "Não")]
    end)
    [headers | rows] |> CSV.encode() |> Enum.to_list() |> IO.iodata_to_binary()
  end

  def export_events_csv(opts \\ []) do
    events = EventManager.Core.list_events(opts)
    headers = ["Título", "Data", "Local", "Vagas", "Inscritos", "Ocupação (%)", "Status"]
    rows = Enum.map(events, fn e ->
      regs = length(e.registrations || [])
      [e.title, Calendar.strftime(e.date, "%d/%m/%Y %H:%M"), e.location, e.max_seats, regs,
       Float.round(regs / max(e.max_seats, 1) * 100, 2), Atom.to_string(e.status)]
    end)
    [headers | rows] |> CSV.encode() |> Enum.to_list() |> IO.iodata_to_binary()
  end

  def get_speaker_stats(speaker_id) do
    events = from(e in Event, where: e.speaker_id == ^speaker_id, preload: [:registrations]) |> Repo.all()
    total_events = length(events)
    total_regs = events |> Enum.map(&length(&1.registrations)) |> Enum.sum()
    %{speaker_id: speaker_id, total_events: total_events, total_registrations: total_regs,
      average_registrations: if(total_events > 0, do: total_regs / total_events, else: 0)}
  end

  defp maybe_limit(query, nil), do: query
  defp maybe_limit(query, limit), do: limit(query, ^limit)
end