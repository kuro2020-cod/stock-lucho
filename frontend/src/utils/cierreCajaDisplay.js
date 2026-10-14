export const METODOS_CIERRE_LABELS = {
  efectivo: 'Efectivo',
  transferencia: 'Transferencia',
  tarjeta: 'Tarjeta',
  fiado: 'Fiado',
  sin_definir: 'Sin definir'
}

export const METODOS_CIERRE_ORDEN = [
  'efectivo',
  'transferencia',
  'tarjeta',
  'fiado',
  'sin_definir'
]

export const METODOS_PROVEEDOR_ORDEN = ['efectivo', 'transferencia']

export const fmtMoney = (n) =>
  `$${Number(n || 0).toLocaleString('es-ES', { minimumFractionDigits: 2, maximumFractionDigits: 2 })}`

export function parseDetalleMetodosCierre(cierre) {
  const raw = cierre?.detalle_metodos
  if (!raw) return null
  if (typeof raw === 'object') return raw
  try {
    return JSON.parse(raw)
  } catch {
    return null
  }
}

export function esDetalleCierreV2(detalle) {
  return detalle && typeof detalle === 'object' && detalle.v === 2 && detalle.neto
}

/** Totales netos por método (compatible con cierres v1 y v2). */
export function lineasTotalesCierre(cierre) {
  const detalle = parseDetalleMetodosCierre(cierre)
  if (!detalle) return []

  const fuente = esDetalleCierreV2(detalle) ? detalle.neto : detalle

  return METODOS_CIERRE_ORDEN.map((key) => ({
    key,
    label: METODOS_CIERRE_LABELS[key] || key,
    total: Number(fuente[key]?.neto ?? fuente[key]?.total ?? 0),
    ventas: Number(fuente[key]?.ventas ?? 0),
    proveedores: Number(fuente[key]?.proveedores ?? 0)
  }))
}

export function seccionesDetalleCierreV2(detalle) {
  if (!esDetalleCierreV2(detalle)) return null

  const ventas = METODOS_CIERRE_ORDEN.map((key) => ({
    key,
    label: METODOS_CIERRE_LABELS[key],
    total: Number(detalle.ventas?.[key]?.total ?? 0),
    movimientos: Number(detalle.ventas?.[key]?.movimientos ?? 0)
  }))

  const proveedores = METODOS_PROVEEDOR_ORDEN.map((key) => ({
    key,
    label: METODOS_CIERRE_LABELS[key],
    total: Number(detalle.proveedores?.[key]?.total ?? 0),
    movimientos: Number(detalle.proveedores?.[key]?.movimientos ?? 0)
  }))

  const neto = METODOS_CIERRE_ORDEN.map((key) => ({
    key,
    label: METODOS_CIERRE_LABELS[key],
    ventas: Number(detalle.neto?.[key]?.ventas ?? 0),
    proveedores: Number(detalle.neto?.[key]?.proveedores ?? 0),
    neto: Number(detalle.neto?.[key]?.neto ?? detalle.neto?.[key]?.total ?? 0),
    movimientos: Number(detalle.neto?.[key]?.movimientos ?? 0)
  }))

  const totalVentas = ventas.reduce((s, x) => s + x.total, 0)
  const totalProveedores = proveedores.reduce((s, x) => s + x.total, 0)
  const totalNeto = neto.reduce((s, x) => s + x.neto, 0)

  return { ventas, proveedores, neto, totalVentas, totalProveedores, totalNeto }
}

export function claseMontoNeto(n) {
  const v = Number(n || 0)
  if (v < 0) return 'text-red-600 dark:text-red-300'
  if (v > 0) return 'text-emerald-700 dark:text-emerald-300'
  return 'text-gray-900 dark:text-slate-100'
}

export const SUBTITULO_RUBROS_CIERRE =
  'Solo las categorías agregadas en el dashboard con Agregar contador'

export function extraRubroCierre() {
  return ''
}

export function esRubroContadorDashboard(key) {
  return String(key || '').startsWith('contador_')
}

export function listaRubrosDashboard(lista) {
  return (Array.isArray(lista) ? lista : []).filter((r) => esRubroContadorDashboard(r?.key))
}

export function lineasRubrosCierre(cierre) {
  const detalle = parseDetalleMetodosCierre(cierre)
  const rubros = detalle?.rubros
  if (!rubros || typeof rubros !== 'object') return []

  const keys = Object.keys(rubros)
    .filter((key) => esRubroContadorDashboard(key))
    .sort((a, b) => {
      const na = Number(a.slice(10))
      const nb = Number(b.slice(10))
      if (Number.isFinite(na) && Number.isFinite(nb) && na !== nb) return na - nb
      return a.localeCompare(b)
    })

  const out = []
  for (const key of keys) {
    const r = rubros[key]
    if (!r || typeof r !== 'object') continue
    out.push({
      key,
      label: r.label || key,
      total: Number(r.total ?? 0),
      movimientos: Number(r.movimientos ?? 0),
      unidades: Number(r.unidades ?? 0)
    })
  }
  return out
}

export function formatAperturaCajaHora(aperturaCaja) {
  const raw = aperturaCaja?.apertura_at ?? aperturaCaja?.created_at
  if (!raw) return null
  const d = new Date(raw)
  if (Number.isNaN(d.getTime())) return null
  return d.toLocaleString('es-AR', {
    day: '2-digit',
    month: '2-digit',
    year: 'numeric',
    hour: '2-digit',
    minute: '2-digit'
  })
}

/** Inicio de caja y fondo dejado al cerrar (si están guardados en el detalle). */
export function datosAperturaCierre(cierre) {
  const detalle = parseDetalleMetodosCierre(cierre)
  const ap = detalle?.apertura_caja
  if (!ap || typeof ap !== 'object') return null
  const montoApertura = Number(ap.monto_apertura)
  const fondoSiguiente = Number(ap.fondo_siguiente)
  if (!Number.isFinite(montoApertura) && !Number.isFinite(fondoSiguiente)) return null
  const diferencia =
    ap.diferencia_fondo != null && Number.isFinite(Number(ap.diferencia_fondo))
      ? Number(ap.diferencia_fondo)
      : Number.isFinite(montoApertura) && Number.isFinite(fondoSiguiente)
        ? Math.round((montoApertura - fondoSiguiente) * 100) / 100
        : null
  return {
    montoApertura: Number.isFinite(montoApertura) ? montoApertura : null,
    fondoSiguiente: Number.isFinite(fondoSiguiente) ? fondoSiguiente : null,
    diferencia,
    registradoPor: ap.registrado_por || null,
    aperturaAt: ap.apertura_at ?? ap.created_at ?? null,
    aperturaHora: formatAperturaCajaHora(ap)
  }
}
