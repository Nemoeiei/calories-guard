import { useEffect, useState } from 'react'
import { Search, User, Loader2, Flame, RefreshCw, X } from 'lucide-react'
import { api } from '../api/client'

interface UserRow {
  user_id: number
  username: string
  email: string
  role_id: number
  created_at: string
  last_login_date?: string
  current_streak?: number
  total_login_days?: number
}

export default function Users() {
  const [users, setUsers] = useState<UserRow[]>([])
  const [search, setSearch] = useState('')
  const [loading, setLoading] = useState(true)
  const [selected, setSelected] = useState<UserRow | null>(null)

  const load = (q = '') => {
    setLoading(true)
    api.getAdminUsers(q)
      .then(data => setUsers(data as UserRow[]))
      .catch(console.error)
      .finally(() => setLoading(false))
  }

  useEffect(() => { load() }, [])

  const handleSearch = (e: React.FormEvent) => {
    e.preventDefault()
    load(search)
  }

  return (
    <div className="space-y-5">
      <div className="flex items-center justify-between">
        <div>
          <h2 className="text-2xl font-bold text-gray-800">ผู้ใช้งาน</h2>
          <p className="text-sm text-gray-500 mt-0.5">ทั้งหมด {users.length} บัญชี</p>
        </div>
        <button onClick={() => load(search)} className="p-2 rounded-xl hover:bg-white border border-gray-200 transition" title="รีเฟรช">
          <RefreshCw size={16} className="text-gray-500" />
        </button>
      </div>

      {/* Search */}
      <form onSubmit={handleSearch} className="flex gap-3">
        <div className="relative flex-1 max-w-sm">
          <Search size={16} className="absolute left-3.5 top-1/2 -translate-y-1/2 text-gray-400" />
          <input
            type="text"
            placeholder="ค้นหาด้วยชื่อหรืออีเมล..."
            value={search}
            onChange={e => setSearch(e.target.value)}
            className="w-full pl-10 pr-4 py-2.5 rounded-xl border border-gray-200 focus:outline-none focus:ring-2 focus:ring-[#628141]/30 focus:border-[#628141] text-sm bg-white"
          />
        </div>
        <button
          type="submit"
          className="px-5 py-2.5 rounded-xl bg-[#628141] text-white text-sm font-semibold hover:bg-[#507034] transition flex items-center gap-2"
        >
          <Search size={15} /> ค้นหา
        </button>
      </form>

      {/* Table */}
      <div className="bg-white rounded-2xl shadow-sm border border-gray-100 overflow-hidden">
        {loading ? (
          <div className="flex items-center justify-center py-16">
            <Loader2 size={28} className="animate-spin text-[#628141]" />
          </div>
        ) : users.length === 0 ? (
          <div className="py-16 text-center text-gray-400 text-sm">ไม่พบผู้ใช้งาน</div>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full text-sm">
              <thead className="bg-gray-50 border-b border-gray-100">
                <tr>
                  <th className="py-3 px-4 text-left text-xs font-semibold text-gray-500 uppercase">ID</th>
                  <th className="py-3 px-4 text-left text-xs font-semibold text-gray-500 uppercase">ชื่อผู้ใช้</th>
                  <th className="py-3 px-4 text-left text-xs font-semibold text-gray-500 uppercase">อีเมล</th>
                  <th className="py-3 px-4 text-center text-xs font-semibold text-gray-500 uppercase">Role</th>
                  <th className="py-3 px-4 text-center text-xs font-semibold text-gray-500 uppercase">Streak</th>
                  <th className="py-3 px-4 text-center text-xs font-semibold text-gray-500 uppercase">วันที่ใช้งาน</th>
                  <th className="py-3 px-4 text-left text-xs font-semibold text-gray-500 uppercase">สมัครเมื่อ</th>
                </tr>
              </thead>
              <tbody>
                {users.map(u => (
                  <tr
                    key={u.user_id}
                    onClick={() => setSelected(u)}
                    className="border-b border-gray-50 hover:bg-gray-50 transition cursor-pointer"
                  >
                    <td className="py-3 px-4 text-gray-400 text-xs">#{u.user_id}</td>
                    <td className="py-3 px-4">
                      <div className="flex items-center gap-2">
                        <div className="w-7 h-7 rounded-full bg-[#E8EFCF] flex items-center justify-center">
                          <User size={13} className="text-[#628141]" />
                        </div>
                        <span className="font-medium text-gray-800">{u.username}</span>
                      </div>
                    </td>
                    <td className="py-3 px-4 text-gray-500">{u.email}</td>
                    <td className="py-3 px-4 text-center">
                      <span className={`text-xs font-semibold px-2.5 py-1 rounded-full ${
                        u.role_id === 1 ? 'bg-purple-100 text-purple-700' : 'bg-[#E8EFCF] text-[#628141]'
                      }`}>
                        {u.role_id === 1 ? '👑 Admin' : '👤 User'}
                      </span>
                    </td>
                    <td className="py-3 px-4 text-center">
                      <span className="flex items-center justify-center gap-1 text-orange-500 font-semibold text-xs">
                        <Flame size={12} /> {u.current_streak ?? 0}
                      </span>
                    </td>
                    <td className="py-3 px-4 text-center text-gray-600 text-xs">{u.total_login_days ?? 0} วัน</td>
                    <td className="py-3 px-4 text-gray-400 text-xs">
                      {u.created_at ? new Date(u.created_at).toLocaleDateString('th-TH') : '—'}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </div>

      {/* Detail modal */}
      {selected && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/40">
          <div className="bg-white rounded-2xl shadow-2xl w-full max-w-sm">
            <div className="flex items-center justify-between px-6 py-4 border-b border-gray-100">
              <h3 className="font-semibold text-gray-800">ข้อมูลผู้ใช้</h3>
              <button onClick={() => setSelected(null)} className="p-1.5 rounded-lg hover:bg-gray-100 transition">
                <X size={18} className="text-gray-500" />
              </button>
            </div>
            <div className="px-6 py-5 space-y-3">
              <div className="flex items-center gap-3 pb-3 border-b border-gray-50">
                <div className="w-12 h-12 rounded-full bg-[#E8EFCF] flex items-center justify-center">
                  <User size={22} className="text-[#628141]" />
                </div>
                <div>
                  <p className="font-bold text-gray-800">{selected.username}</p>
                  <p className="text-sm text-gray-500">{selected.email}</p>
                </div>
              </div>
              {[
                ['User ID', `#${selected.user_id}`],
                ['Role', selected.role_id === 1 ? '👑 Admin' : '👤 User'],
                ['Streak', `🔥 ${selected.current_streak ?? 0} วัน`],
                ['วันที่ใช้งานทั้งหมด', `${selected.total_login_days ?? 0} วัน`],
                ['เข้าสู่ระบบล่าสุด', selected.last_login_date ? new Date(selected.last_login_date).toLocaleDateString('th-TH') : '—'],
                ['สมัครเมื่อ', selected.created_at ? new Date(selected.created_at).toLocaleDateString('th-TH') : '—'],
              ].map(([label, value]) => (
                <div key={label} className="flex justify-between text-sm">
                  <span className="text-gray-500">{label}</span>
                  <span className="font-medium text-gray-800">{value}</span>
                </div>
              ))}
            </div>
          </div>
        </div>
      )}
    </div>
  )
}
