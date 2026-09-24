import { esRolAdmin } from './roles'

function esHostnameLocalOPrivado(hostname) {
  const h = String(hostname || '').toLowerCase()
  if (!h || h === 'localhost' || h === '127.0.0.1' || h === '::1') return true
  if (h.endsWith('.local')) return true
  if (h.startsWith('192.168.') || h.startsWith('10.')) return true
  if (/^172\.(1[6-9]|2\d|3[0-1])\./.test(h)) return true
  return false
}

export function esHostExterno() {
  if (typeof window === 'undefined') return false
  return !esHostnameLocalOPrivado(window.location.hostname)
}

export function esRolExterno(user) {
  const rol = typeof user === 'string' ? user : user?.rol
  return String(rol || '').toUpperCase() === 'EXTERNO'
}

/** Entró por ngrok / internet (no es la red del local). */
export function esAccesoRemoto(user) {
  return Boolean(user?.accesoExterno) || esHostExterno()
}

/** Solo EXTERNO no puede vender. USER, ADMIN y SUPER sí, también desde el celular. */
export function esAccesoLimitado(user) {
  return esRolExterno(user)
}

/** Inicio según rol. EXTERNO no tiene Ventas. */
export function rutaHome(user) {
  const admin = esRolAdmin(user?.rol)
  if (esAccesoLimitado(user)) return admin ? '/' : '/faltantes'
  return admin ? '/' : '/ventas'
}
