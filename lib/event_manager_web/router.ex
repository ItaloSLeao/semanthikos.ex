defmodule EventManagerWeb.Router do
  use EventManagerWeb, :router
  import EventManagerWeb.UserAuth

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {EventManagerWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_user
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", EventManagerWeb do
    pipe_through :browser

    get "/", PageController, :home
    get "/events", EventController, :index
    get "/events/:id", EventController, :show
    get "/certificates/verify", CertificateController, :verify

    # Auth routes
    get "/users/register", AuthController, :new_registration
    post "/users/register", AuthController, :create_registration
    get "/users/log_in", AuthController, :new_session
    post "/users/log_in", AuthController, :create_session
    get "/users/reset_password", AuthController, :new_reset_password
    post "/users/reset_password", AuthController, :create_reset_password
    get "/users/reset_password/:token", AuthController, :edit_reset_password
    put "/users/reset_password/:token", AuthController, :update_reset_password
  end

  scope "/", EventManagerWeb do
    pipe_through [:browser, :require_authenticated_user]

    get "/users/settings", AuthController, :edit_settings
    put "/users/settings", AuthController, :update_settings
    get "/users/settings/confirm_email/:token", AuthController, :confirm_email

    get "/my/certificates", CertificateController, :index
    get "/my/certificates/:id/download", CertificateController, :download
    get "/my/registrations", EventController, :my_registrations

    post "/events/:id/register", EventController, :register
    delete "/events/:id/register", EventController, :cancel_registration

    live_session :authenticated_user, on_mount: [{EventManagerWeb.UserAuth, :ensure_authenticated}] do
      live "/events/:id/chat", EventChatLive
      live "/events/:id/dashboard", EventDashboardLive
    end
  end

  scope "/speaker", EventManagerWeb do
    pipe_through [:browser, :require_authenticated_user, :require_speaker]

    get "/events", EventController, :speaker_events
    get "/events/:id/attendees", EventController, :speaker_attendees
    post "/events/:event_id/attendance", EventController, :mark_attendance
    post "/events/:event_id/certificates", EventController, :generate_certificates
  end

  scope "/admin", EventManagerWeb do
    pipe_through [:browser, :require_authenticated_user, :require_admin]

    get "/", AdminController, :reports
    get "/events", AdminController, :events
    get "/events/new", AdminController, :new_event
    post "/events", AdminController, :create_event
    get "/events/:id/edit", AdminController, :edit_event
    put "/events/:id", AdminController, :update_event
    delete "/events/:id", AdminController, :delete_event
    post "/events/:id/publish", AdminController, :publish_event
    post "/events/:id/cancel", AdminController, :cancel_event

    get "/users", AdminController, :users
    get "/users/new", AdminController, :new_user
    post "/users", AdminController, :create_user
    get "/users/:id/edit", AdminController, :edit_user
    put "/users/:id", AdminController, :update_user
    delete "/users/:id", AdminController, :delete_user

    get "/reports/occupancy", AdminController, :occupancy_report
    get "/reports/participation", AdminController, :participation_report
    get "/reports/export/csv", AdminController, :export_csv

    get "/certificates", AdminController, :certificates
    post "/certificates/generate/:event_id", AdminController, :generate_certificates

    live_session :admin_user, on_mount: [{EventManagerWeb.UserAuth, :ensure_authenticated}] do
      live "/dashboard", AdminDashboardLive
    end
  end

  scope "/", EventManagerWeb do
    pipe_through :browser
    get "/users/log_out", AuthController, :delete_session
    delete "/users/log_out", AuthController, :delete_session
  end

  scope "/api", EventManagerWeb do
    pipe_through :api
    get "/events", Api.EventController, :index
    get "/events/:id", Api.EventController, :show
    get "/events/:id/stats", Api.EventController, :stats
  end
end
