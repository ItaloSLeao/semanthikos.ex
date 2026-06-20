defmodule EventManagerWeb.CoreComponents do
  @moduledoc """
  Core UI components — redesigned with the Semanthikos visual identity.
  Paleta: ink (escuro), gold (âmbar), cyan (verde-água), paper (creme claro).
  """
  use Phoenix.Component
  use Gettext, backend: EventManagerWeb.Gettext

  # ── Flash ──────────────────────────────────────────────────────────────────

  @doc "Renders a flash notification."
  attr :kind, :atom, values: [:info, :error, :warning, :success], default: :info
  attr :flash, :any, default: nil
  attr :title, :string, default: nil

  def flash(%{kind: kind, flash: flash} = assigns) do
    assigns = assign(assigns, :msg, flash[kind])

    if assigns.msg do
      ~H"""
      <div style={"margin: 1rem 0; padding: 1rem 1.25rem; border-radius: 10px; display: flex; align-items: flex-start; gap: 10px; border-left: 4px solid #{flash_accent_color(@kind)}; #{flash_bg(@kind)}"} role="alert">
        <span style="font-size: 1.1rem; flex-shrink: 0; margin-top: 1px;"><%= flash_icon(@kind) %></span>
        <p style={"margin: 0; font-size: 0.9rem; font-weight: 500; #{flash_text_color(@kind)}"}><%= @msg %></p>
      </div>
      """
    else
      ~H""
    end
  end

  defp flash_bg(:info),    do: "background: #eff6ff;"
  defp flash_bg(:success), do: "background: #f0fdf4;"
  defp flash_bg(:warning), do: "background: #fffbeb;"
  defp flash_bg(:error),   do: "background: #fef2f2;"

  defp flash_accent_color(:info),    do: "#3b82f6"
  defp flash_accent_color(:success), do: "#22c55e"
  defp flash_accent_color(:warning), do: "#d4a547"
  defp flash_accent_color(:error),   do: "#ef4444"

  defp flash_text_color(:info),    do: "color: #1e40af;"
  defp flash_text_color(:success), do: "color: #15803d;"
  defp flash_text_color(:warning), do: "color: #92400e;"
  defp flash_text_color(:error),   do: "color: #b91c1c;"

  defp flash_icon(:info),    do: "ℹ️"
  defp flash_icon(:success), do: "✅"
  defp flash_icon(:warning), do: "⚠️"
  defp flash_icon(:error),   do: "❌"

  # ── Button ─────────────────────────────────────────────────────────────────

  @doc "Renders a styled button."
  attr :type, :string, default: "button"
  attr :class, :string, default: ""
  attr :variant, :atom, values: [:primary, :secondary, :danger, :success], default: :primary
  attr :rest, :global, include: ~w(disabled form name value)

  slot :inner_block, required: true

  def button(assigns) do
    ~H"""
    <button
      type={@type}
      style={button_style(@variant)}
      {@rest}
    >
      <%= render_slot(@inner_block) %>
    </button>
    """
  end

  defp button_style(:primary),   do: "padding:10px 22px; background:var(--ink); color:white; border:none; border-radius:8px; font-family:'DM Sans',sans-serif; font-size:0.875rem; font-weight:500; cursor:pointer; transition:background 0.2s;"
  defp button_style(:secondary), do: "padding:10px 22px; background:var(--smoke); color:var(--ink); border:1px solid #e0ddd8; border-radius:8px; font-family:'DM Sans',sans-serif; font-size:0.875rem; font-weight:500; cursor:pointer; transition:background 0.2s;"
  defp button_style(:danger),    do: "padding:10px 22px; background:#dc2626; color:white; border:none; border-radius:8px; font-family:'DM Sans',sans-serif; font-size:0.875rem; font-weight:500; cursor:pointer; transition:opacity 0.2s;"
  defp button_style(:success),   do: "padding:10px 22px; background:var(--gold); color:var(--ink); border:none; border-radius:8px; font-family:'DM Sans',sans-serif; font-size:0.875rem; font-weight:600; cursor:pointer; transition:opacity 0.2s;"

  # ── Card ───────────────────────────────────────────────────────────────────

  @doc "Renders a card container."
  attr :class, :string, default: ""
  slot :header
  slot :inner_block, required: true
  slot :footer

  def card(assigns) do
    ~H"""
    <div style="background:white; border:1px solid #eae9e4; border-radius:12px; overflow:hidden;">
      <%= if @header != [] do %>
        <div style="padding:1.25rem 1.5rem; border-bottom:1px solid #f0ede8; background:var(--smoke);">
          <%= render_slot(@header) %>
        </div>
      <% end %>
      <div style="padding:1.5rem;">
        <%= render_slot(@inner_block) %>
      </div>
      <%= if @footer != [] do %>
        <div style="padding:1rem 1.5rem; border-top:1px solid #f0ede8; background:var(--smoke);">
          <%= render_slot(@footer) %>
        </div>
      <% end %>
    </div>
    """
  end

  # ── Badge ──────────────────────────────────────────────────────────────────

  @doc "Renders a small badge."
  attr :text, :string, required: true
  attr :variant, :atom, values: [:default, :success, :warning, :danger, :info], default: :default

  def badge(assigns) do
    ~H"""
    <span style={badge_style(@variant)}>
      <%= @text %>
    </span>
    """
  end

  defp badge_style(:default), do: "display:inline-flex;align-items:center;padding:3px 10px;border-radius:100px;font-size:0.72rem;font-weight:600;letter-spacing:0.04em;background:#f3f2ee;color:#6b7280;border:1px solid #e0ddd8;"
  defp badge_style(:success),  do: "display:inline-flex;align-items:center;padding:3px 10px;border-radius:100px;font-size:0.72rem;font-weight:600;letter-spacing:0.04em;background:rgba(22,163,74,0.1);color:#15803d;border:1px solid rgba(22,163,74,0.2);"
  defp badge_style(:warning),  do: "display:inline-flex;align-items:center;padding:3px 10px;border-radius:100px;font-size:0.72rem;font-weight:600;letter-spacing:0.04em;background:rgba(212,165,71,0.12);color:#92400e;border:1px solid rgba(212,165,71,0.3);"
  defp badge_style(:danger),   do: "display:inline-flex;align-items:center;padding:3px 10px;border-radius:100px;font-size:0.72rem;font-weight:600;letter-spacing:0.04em;background:rgba(220,38,38,0.08);color:#b91c1c;border:1px solid rgba(220,38,38,0.15);"
  defp badge_style(:info),     do: "display:inline-flex;align-items:center;padding:3px 10px;border-radius:100px;font-size:0.72rem;font-weight:600;letter-spacing:0.04em;background:rgba(59,130,246,0.08);color:#1d4ed8;border:1px solid rgba(59,130,246,0.15);"

  # ── Input ──────────────────────────────────────────────────────────────────

  @doc "Renders a labeled input field."
  attr :name, :string, required: true
  attr :label, :string, default: nil
  attr :type, :string, default: "text"
  attr :value, :any, default: nil
  attr :errors, :list, default: []
  attr :required, :boolean, default: false
  attr :rest, :global

  def input(assigns) do
    ~H"""
    <div style="display:flex; flex-direction:column; gap:6px;">
      <%= if @label do %>
        <label for={@name} style="font-family:'Helvetica Neue', Helvetica, Arial, sans-serif; font-size:0.95rem; font-weight:500; color:var(--text-primary); letter-spacing:0.01em;">
          <%= @label %>
          <%= if @required do %>
            <span style="color:var(--danger); margin-left:2px;">*</span>
          <% end %>
        </label>
      <% end %>
      <input
        type={@type}
        name={@name}
        id={@name}
        value={@value}
        required={@required}
        class="input-field"
        {@rest}
      />
      <%= if @errors != [] do %>
        <div style="font-size:0.8rem; color:var(--danger);">
          <%= for error <- @errors do %>
            <p style="margin:0;"><%= error %></p>
          <% end %>
        </div>
      <% end %>
    </div>
    """
  end

  # ── Event status badge ──────────────────────────────────────────────────────

  @doc "Renders a badge for event status."
  attr :status, :atom, required: true

  def event_status_badge(%{status: :draft} = assigns) do
    ~H"""
      <.badge text="Rascunho" variant={:default} />
      """
  end

  def event_status_badge(%{status: :published} = assigns) do
    ~H"""
      <.badge text="Publicado" variant={:info} />
      """
  end

  def event_status_badge(%{status: :ongoing} = assigns) do
    ~H"""
      <.badge text="Em andamento" variant={:success} />
      """
  end

  def event_status_badge(%{status: :completed} = assigns) do
    ~H"""
      <.badge text="Concluído" variant={:default} />
      """
  end

  def event_status_badge(%{status: :cancelled} = assigns) do
    ~H"""
      <.badge text="Cancelado" variant={:danger} />
      """
  end

  # ── Role badge ─────────────────────────────────────────────────────────────

  @doc "Renders a badge for user role."
  attr :role, :atom, required: true

  def role_badge(%{role: :admin} = assigns) do
    ~H"""
      <.badge text="Admin" variant={:danger} />
      """
  end

  def role_badge(%{role: :speaker} = assigns) do
    ~H"""
      <.badge text="Palestrante" variant={:warning} />
      """
  end

  def role_badge(%{role: :student} = assigns) do
    ~H"""
      <.badge text="Estudante" variant={:default} />
      """
  end

  # ── Formatted datetime ─────────────────────────────────────────────────────

  @doc "Renders a formatted datetime element."
  attr :datetime, :any, required: true
  attr :format, :atom, values: [:short, :long, :date_only], default: :short

  def formatted_datetime(assigns) do
    ~H"""
    <time datetime={format_iso(@datetime)}>
      <%= format_datetime(@datetime, @format) %>
    </time>
    """
  end

  defp format_datetime(datetime, :short),     do: Calendar.strftime(datetime, "%d/%m/%Y %H:%M")
  defp format_datetime(datetime, :long),      do: Calendar.strftime(datetime, "%A, %d de %B de %Y às %H:%M")
  defp format_datetime(datetime, :date_only), do: Calendar.strftime(datetime, "%d/%m/%Y")
  defp format_iso(datetime),                  do: Calendar.strftime(datetime, "%Y-%m-%dT%H:%M:%S")
end
