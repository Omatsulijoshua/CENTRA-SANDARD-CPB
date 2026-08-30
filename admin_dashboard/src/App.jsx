import React from 'react'
import { BrowserRouter as Router, Routes, Route } from 'react-router-dom'
import AdminGate from './auth/AdminGate'
import Login from './pages/Login'
import AdminLayout from './layout/AdminLayout'

export default function App() {
  return (
    <Router>
      <Routes>
        <Route path="/login" element={<Login />} />
        <Route
          path="/*"
          element={
            <AdminGate>
              <AdminLayout />
            </AdminGate>
          }
        />
      </Routes>
    </Router>
  )
}
