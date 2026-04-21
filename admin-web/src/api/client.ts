const BASE_URL = import.meta.env.VITE_API_BASE_URL || 'http://localhost:8000'

export function normalizeImageUrl(url: string | null | undefined): string | null {
  if (!url) return null
  return url.replace(/https?:\/\/10\.0\.2\.2(:\d+)?/, BASE_URL)
}

async function req<T>(path: string, options: RequestInit = {}): Promise<T> {
  const res = await fetch(`${BASE_URL}${path}`, {
    headers: { 'Content-Type': 'application/json', ...options.headers },
    ...options,
  })
  if (!res.ok) {
    const err = await res.json().catch(() => ({ detail: `HTTP ${res.status}` }))
    throw new Error(err.detail || `HTTP ${res.status}`)
  }
  return res.json() as Promise<T>
}

export const api = {
  // ── Auth ──────────────────────────────────────────
  login: (email: string, password: string) =>
    req<any>('/login', { method: 'POST', body: JSON.stringify({ email, password }) }),

  // ── Foods ─────────────────────────────────────────
  getFoods: () => req<any[]>('/foods'),
  createFood: (data: object) =>
    req<any>('/foods', { method: 'POST', body: JSON.stringify(data) }),
  updateFood: (id: number, data: object) =>
    req<any>(`/foods/${id}`, { method: 'PUT', body: JSON.stringify(data) }),
  patchFood: (id: number, data: object) =>
    req<any>(`/foods/${id}`, { method: 'PATCH', body: JSON.stringify(data) }),
  deleteFood: (id: number) =>
    req<any>(`/foods/${id}`, { method: 'DELETE' }),

  // ── Temp Foods (v13 flow) ──────────────────────────
  getTempFoods: (status = 'pending') =>
    req<any[]>(`/admin/temp-foods?status=${status}`),
  getPendingCount: () =>
    req<{ count: number }>('/admin/temp-foods/pending-count'),
  getSimilarFoods: (name: string) =>
    req<any[]>(`/admin/foods/similar?name=${encodeURIComponent(name)}`),
  approveTempFood: (tfId: number, adminId: number, data: object) =>
    req<any>(`/admin/temp-foods/${tfId}/approve`, {
      method: 'POST',
      body: JSON.stringify({ admin_id: adminId, ...data }),
    }),
  rejectTempFood: (tfId: number) =>
    req<any>(`/admin/temp-foods/${tfId}`, { method: 'DELETE' }),

  // ── Food Requests (legacy) ────────────────────────
  getFoodRequests: () => req<any[]>('/admin/food-requests'),
  reviewFoodRequest: (id: number, adminId: number, status: 'approved' | 'rejected', data?: object) =>
    req<any>(`/admin/food-requests/${id}`, {
      method: 'PUT',
      body: JSON.stringify({ admin_id: adminId, status, ...data }),
    }),

  // ── Users ─────────────────────────────────────────
  getAdminUsers: (search = '') => req<any[]>(`/admin/users${search ? `?search=${encodeURIComponent(search)}` : ''}`),
  getUser: (id: number) => req<any>(`/users/${id}`),
}
