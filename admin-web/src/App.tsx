import type { ReactNode } from 'react'
import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom'
import { AuthProvider, useAuth } from './context/AuthContext'
import Layout from './components/Layout'
import Login from './pages/Login'
import Dashboard from './pages/Dashboard'
import Foods from './pages/Foods'
import FoodRequests from './pages/FoodRequests'
import Users from './pages/Users'

function Guard({ children }: { children: ReactNode }) {
  const { auth } = useAuth()
  if (!auth || auth.role_id !== 1) return <Navigate to="/login" replace />
  return <>{children}</>
}

function AppRoutes() {
  const { auth } = useAuth()
  const isAdmin = auth?.role_id === 1

  return (
    <Routes>
      <Route
        path="/login"
        element={isAdmin ? <Navigate to="/" replace /> : <Login />}
      />
      <Route
        path="/"
        element={
          <Guard>
            <Layout />
          </Guard>
        }
      >
        <Route index element={<Dashboard />} />
        <Route path="foods" element={<Foods />} />
        <Route path="food-requests" element={<FoodRequests />} />
        <Route path="users" element={<Users />} />
      </Route>
      <Route path="*" element={<Navigate to="/" replace />} />
    </Routes>
  )
}

export default function App() {
  return (
    <AuthProvider>
      <BrowserRouter>
        <AppRoutes />
      </BrowserRouter>
    </AuthProvider>
  )
}
