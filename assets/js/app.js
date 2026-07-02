/**
 * app.js
 * 
 * Este arquivo atua como o ponto de entrada principal para a interface front-end do projeto Event Manager.
 * Ele inicializa a comunicação cliente-servidor através de WebSockets e gerencia as conexões do Phoenix LiveView e Channels.
 * 
 * Funcionalidades Principais:
 * - Define componentes customizados (ex: LocalTime).
 * - Configura e conecta o `LiveSocket` que permite que o Phoenix LiveView atualize a página em tempo real.
 * - Registra `Hooks` do JavaScript para o LiveView (como o `ChatScroll` que mantém o scroll das mensagens do chat embaixo).
 * - Conecta o socket padrão (`/socket`) usado pelos canais normais do Phoenix, passando o token do usuário.
 * - Este arquivo é essencial para permitir o funcionamento da funcionalidade mais chamativa: os chats ao vivo em tempo real.
 */
// Import Phoenix dependencies
import "phoenix_html"
import {Socket} from "phoenix"
import {LiveSocket} from "phoenix_live_view"
import topbar from "../vendor/topbar"

class LocalTime extends HTMLElement {
  connectedCallback() {
    const dt = new Date(this.getAttribute('datetime') + 'Z');
    this.textContent = dt.toLocaleTimeString([], {hour: '2-digit', minute:'2-digit'});
  }
}
customElements.define('local-time', LocalTime);

// Initialize Phoenix Channels
let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")

let Hooks = {}
Hooks.ChatScroll = {
  mounted() { this.el.scrollTop = this.el.scrollHeight },
  updated() { this.el.scrollTop = this.el.scrollHeight }
}

let liveSocket = new LiveSocket("/live", Socket, {
  params: {_csrf_token: csrfToken},
  hooks: Hooks
})

// Connect to LiveView
liveSocket.connect()

// Expose liveSocket for debugging
window.liveSocket = liveSocket

// Topbar progress
topbar.config({barColors: {0: "#29d"}, shadowColor: "rgba(0, 0, 0, .3)"})
window.addEventListener("phx:page-loading-start", info => topbar.show())
window.addEventListener("phx:page-loading-stop", info => topbar.hide())

// WebSocket connection
let socket = new Socket("/socket", {params: {token: window.userToken}})
socket.connect()

// Export socket for use in other modules
export default socket