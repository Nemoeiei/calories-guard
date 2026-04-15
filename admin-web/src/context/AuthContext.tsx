import { createContext, useContext, useState, type ReactNode } from 'react'
import type { AuthState } from '../types'

interface AuthCtx {
  auth: AuthState | null
  login: (data: AuthState) => void
  logout: () => void
}

const Ctx = createContext<AuthCtx | null>(null)
const KEY = 'cg_admin_auth'

export function AuthProvider({ children }: { children: ReactNode }) {
  const [auth, setAuth] = useState<AuthState | null>(() => {
    try {
      const s = localStorage.getItem(KEY)
      return s ? (JSON.parse(s) as AuthState) : null
    } catch {
      return null
    }
  })

  const login = (data: AuthState) => {
    localStorage.setItem(KEY, JSON.stringify(data))
    setAuth(data)
  }

  const logout = () => {
    localStorage.removeItem(KEY)
    setAuth(null)
  }

  return <Ctx.Provider value={{ auth, login, logout }}>{children}</Ctx.Provider>
}

export function useAuth() {
  const ctx = useContext(Ctx)
  if (!ctx) throw new Error('useAuth must be inside AuthProvider')
  return ctx
}
