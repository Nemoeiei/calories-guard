import { useEffect, useState } from 'react'
import { CheckCircle, Languages, Loader2, RefreshCw, XCircle } from 'lucide-react'
import { api } from '../api/client'
import { useAuth } from '../context/AuthContext'
import type { RegionalNameSubmission, SubmissionStatus, ThaiRegion } from '../types'

const REGION_LABELS: Record<ThaiRegion, string> = {
  central: 'ภาคกลาง',
  northern: 'ภาคเหนือ',
  northeastern: 'ภาคอีสาน',
  southern: 'ภาคใต้',
}

const STATUS_LABELS: Record<SubmissionStatus, string> = {
  pending: 'รอตรวจ',
  approved: 'อนุมัติแล้ว',
  rejected: 'ปฏิเสธแล้ว',
}

interface Draft {
  isPrimary: boolean
  popularity: string
}

function formatDate(value: string | null | undefined) {
  if (!value) return '—'
  const date = new Date(value)
  if (Number.isNaN(date.getTime())) return '—'
  return date.toLocaleDateString('th-TH', {
    day: '2-digit',
    month: 'short',
    year: '2-digit',
  })
}

export default function RegionalNames() {
  const { auth } = useAuth()
  const adminId = auth?.user_id ?? 0
  const [status, setStatus] = useState<SubmissionStatus>('pending')
  const [items, setItems] = useState<RegionalNameSubmission[]>([])
  const [drafts, setDrafts] = useState<Record<number, Draft>>({})
  const [loading, setLoading] = useState(true)
  const [actionId, setActionId] = useState<number | null>(null)
  const [toast, setToast] = useState('')

  const showToast = (msg: string) => {
    setToast(msg)
    setTimeout(() => setToast(''), 3000)
  }

  const load = () => {
    setLoading(true)
    api
      .getRegionalNameSubmissions(status)
      .then(rows => {
        const nextItems = rows as RegionalNameSubmission[]
        setItems(nextItems)
        setDrafts(
          Object.fromEntries(
            nextItems.map(item => [
              item.submission_id,
              {
                isPrimary: true,
                popularity: item.popularity?.toString() ?? '',
              },
            ]),
          ),
        )
      })
      .catch(err => {
        console.error(err)
        showToast('โหลดรายการไม่สำเร็จ')
      })
      .finally(() => setLoading(false))
  }

  useEffect(() => {
    load()
  }, [status])

  const updateDraft = (id: number, patch: Partial<Draft>) => {
    setDrafts(current => ({
      ...current,
      [id]: {
        isPrimary: current[id]?.isPrimary ?? true,
        popularity: current[id]?.popularity ?? '',
        ...patch,
      },
    }))
  }

  const approve = async (item: RegionalNameSubmission) => {
    const draft = drafts[item.submission_id] ?? { isPrimary: true, popularity: '' }
    const popularity = draft.popularity ? Number(draft.popularity) : null
    setActionId(item.submission_id)
    try {
      await api.approveRegionalNameSubmission(item.submission_id, adminId, {
        is_primary: draft.isPrimary,
        popularity,
      })
      showToast('อนุมัติชื่อท้องถิ่นแล้ว')
      load()
    } catch (err: unknown) {
      alert(err instanceof Error ? err.message : 'เกิดข้อผิดพลาด')
    } finally {
      setActionId(null)
    }
  }

  const reject = async (item: RegionalNameSubmission) => {
    if (!confirm(`ปฏิเสธชื่อ "${item.name_th}"?`)) return
    setActionId(item.submission_id)
    try {
      await api.rejectRegionalNameSubmission(item.submission_id, adminId)
      showToast('ปฏิเสธชื่อท้องถิ่นแล้ว')
      load()
    } catch (err: unknown) {
      alert(err instanceof Error ? err.message : 'เกิดข้อผิดพลาด')
    } finally {
      setActionId(null)
    }
  }

  return (
    <div className="space-y-5">
      {toast && (
        <div className="fixed top-5 right-5 z-50 px-5 py-3 bg-gray-800 text-white rounded-xl shadow-xl text-sm font-medium">
          {toast}
        </div>
      )}

      <div className="flex flex-col gap-4 lg:flex-row lg:items-center lg:justify-between">
        <div>
          <div className="flex items-center gap-2">
            <Languages size={22} className="text-[#628141]" />
            <h2 className="text-2xl font-bold text-gray-800">ชื่ออาหารท้องถิ่น</h2>
          </div>
          <p className="text-sm text-gray-500 mt-1">
            ตรวจคำเสนอชื่อภาคเหนือ อีสาน ใต้ และกลาง แล้วอนุมัติเข้า search/display
          </p>
        </div>

        <div className="flex items-center gap-2">
          {(['pending', 'approved', 'rejected'] as SubmissionStatus[]).map(s => (
            <button
              key={s}
              onClick={() => setStatus(s)}
              className={`px-3 py-2 rounded-xl text-sm font-medium border transition ${
                status === s
                  ? 'bg-[#628141] text-white border-[#628141]'
                  : 'bg-white text-gray-600 border-gray-200 hover:bg-gray-50'
              }`}
            >
              {STATUS_LABELS[s]}
            </button>
          ))}
          <button
            onClick={load}
            className="p-2 rounded-xl hover:bg-white border border-gray-200 transition"
            title="รีเฟรช"
          >
            <RefreshCw size={16} className="text-gray-500" />
          </button>
        </div>
      </div>

      <div className="bg-white rounded-2xl shadow-sm border border-gray-100 overflow-hidden">
        {loading ? (
          <div className="flex items-center justify-center py-16">
            <div className="w-8 h-8 border-4 border-[#628141] border-t-transparent rounded-full animate-spin" />
          </div>
        ) : items.length === 0 ? (
          <div className="py-16 text-center text-gray-400 text-sm">
            ไม่มีชื่อท้องถิ่นในสถานะนี้
          </div>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full text-sm">
              <thead className="bg-gray-50 border-b border-gray-100">
                <tr>
                  <th className="py-3 px-4 text-left text-xs font-semibold text-gray-500 uppercase">อาหารหลัก</th>
                  <th className="py-3 px-4 text-left text-xs font-semibold text-gray-500 uppercase">ชื่อที่เสนอ</th>
                  <th className="py-3 px-4 text-left text-xs font-semibold text-gray-500 uppercase">ภูมิภาค</th>
                  <th className="py-3 px-4 text-left text-xs font-semibold text-gray-500 uppercase">ผู้เสนอ</th>
                  <th className="py-3 px-4 text-left text-xs font-semibold text-gray-500 uppercase">วันที่</th>
                  <th className="py-3 px-4 text-center text-xs font-semibold text-gray-500 uppercase">ตั้งค่า</th>
                  <th className="py-3 px-4 text-center text-xs font-semibold text-gray-500 uppercase">จัดการ</th>
                </tr>
              </thead>
              <tbody>
                {items.map(item => {
                  const draft = drafts[item.submission_id] ?? {
                    isPrimary: true,
                    popularity: item.popularity?.toString() ?? '',
                  }
                  const busy = actionId === item.submission_id
                  const canReview = item.status === 'pending'

                  return (
                    <tr key={item.submission_id} className="border-b border-gray-50 hover:bg-gray-50 transition">
                      <td className="py-3 px-4">
                        <div className="font-medium text-gray-800">{item.food_name}</div>
                        <div className="text-xs text-gray-400">food_id: {item.food_id}</div>
                      </td>
                      <td className="py-3 px-4 font-semibold text-[#2D4A1C]">{item.name_th}</td>
                      <td className="py-3 px-4 text-gray-600">{REGION_LABELS[item.region]}</td>
                      <td className="py-3 px-4">
                        <div className="text-gray-600">{item.requester_name}</div>
                        <div className="text-xs text-gray-400">user_id: {item.user_id}</div>
                      </td>
                      <td className="py-3 px-4 text-gray-400 text-xs">{formatDate(item.created_at)}</td>
                      <td className="py-3 px-4">
                        {canReview ? (
                          <div className="flex items-center justify-center gap-3">
                            <label className="flex items-center gap-1.5 text-xs text-gray-600 whitespace-nowrap">
                              <input
                                type="checkbox"
                                checked={draft.isPrimary}
                                onChange={e => updateDraft(item.submission_id, { isPrimary: e.target.checked })}
                                className="rounded border-gray-300 text-[#628141] focus:ring-[#628141]"
                              />
                              primary
                            </label>
                            <select
                              value={draft.popularity}
                              onChange={e => updateDraft(item.submission_id, { popularity: e.target.value })}
                              className="px-2 py-1.5 rounded-lg border border-gray-200 text-xs focus:outline-none focus:ring-2 focus:ring-[#628141]/30"
                            >
                              <option value="">popularity</option>
                              {[1, 2, 3, 4, 5].map(n => (
                                <option key={n} value={n}>{n}</option>
                              ))}
                            </select>
                          </div>
                        ) : (
                          <span className="block text-center text-xs text-gray-400">
                            {STATUS_LABELS[item.status]}
                          </span>
                        )}
                      </td>
                      <td className="py-3 px-4">
                        {canReview ? (
                          <div className="flex items-center justify-center gap-2">
                            <button
                              onClick={() => approve(item)}
                              disabled={busy}
                              className="flex items-center gap-1 px-3 py-1.5 rounded-lg bg-green-50 text-green-700 hover:bg-green-100 text-xs font-medium transition disabled:opacity-60"
                            >
                              {busy ? <Loader2 size={13} className="animate-spin" /> : <CheckCircle size={13} />}
                              อนุมัติ
                            </button>
                            <button
                              onClick={() => reject(item)}
                              disabled={busy}
                              className="flex items-center gap-1 px-3 py-1.5 rounded-lg bg-red-50 text-red-600 hover:bg-red-100 text-xs font-medium transition disabled:opacity-60"
                            >
                              <XCircle size={13} />
                              ปฏิเสธ
                            </button>
                          </div>
                        ) : (
                          <div className="text-center text-xs text-gray-400">
                            reviewed {formatDate(item.reviewed_at)}
                          </div>
                        )}
                      </td>
                    </tr>
                  )
                })}
              </tbody>
            </table>
          </div>
        )}
      </div>
    </div>
  )
}
