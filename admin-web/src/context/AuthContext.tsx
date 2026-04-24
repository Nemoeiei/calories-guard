import {
  createContext,
  useContext,
  useEffect,
  useRef,
  useState,
  type ReactNode,
} from 'react'
import type { AuthState } from '../types'
import { configureApiAuth } from '../api/client'

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

  // Keep latest auth in a ref so configureApiAuth's getter always sees
  // the current token (React closures would otherwise snapshot the old one).
  const authRef = useRef(auth)
  authRef.current = auth

  const login = (data: AuthState) => {
    localStorage.setItem(KEY, JSON.stringify(data))
    setAuth(data)
  }

  const logout = () => {
    localStorage.removeItem(KEY)
    setAuth(null)
  }

  // Wire api/client.ts once — getter reads ref (always fresh),
  // 401 handler clears auth so the app bounces back to /login.
  useEffect(() => {
    configureApiAuth(
      () => authRef.current?.access_token ?? null,
      () => {
        localStorage.removeItem(KEY)
        setAuth(null)
      },
    )
  }, [])

  return (
    <Ctx.Provider value={{ auth, login, logout }}>{children}</Ctx.Provider>
  )
}

export function useAuth() {
  const ctx = useContext(Ctx)
  if (!ctx) throw new Error('useAuth must be inside AuthProvider')
  return ctx
}
