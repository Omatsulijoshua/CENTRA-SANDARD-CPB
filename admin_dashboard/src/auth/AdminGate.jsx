import React, { useEffect, useMemo, useState } from 'react'
import { Navigate, useLocation } from 'react-router-dom'
import { onAuthStateChanged } from 'firebase/auth'
import { doc, getDoc } from 'firebase/firestore'
import { auth, db, isConfigValid } from '../firebase/client'

export default function AdminGate({ children }) {
  const location = useLocation()
  const [state, setState] = useState({ loading: true, authed: false, isAdmin: false })

  if (!isConfigValid) {
    return (
      <div style={{ padding: 40, background: '#0f172a', color: 'white', minHeight: '100vh', display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center' }}>
        <h2 style={{ color: '#ef4444', marginBottom: 16 }}>Firebase Configuration Missing</h2>
        <p style={{ color: '#94a3b8', textAlign: 'center', maxWidth: 500, lineHeight: 1.6 }}>
          The Admin Dashboard requires a valid Firebase configuration to function. 
          Please create a <code>.env</code> file in the <code>admin_dashboard</code> directory 
          using <code>.env.example</code> as a template.
        </p>
      </div>
    )
  }

  useEffect(() => {
    const unsub = onAuthStateChanged(auth, async (user) => {
      if (!user) {
        setState({ loading: false, authed: false, isAdmin: false })
        return
      }
      try {
        const adminDoc = await getDoc(doc(db, 'admins', user.uid))
        setState({ loading: false, authed: true, isAdmin: adminDoc.exists() })
      } catch {
        setState({ loading: false, authed: true, isAdmin: false })
      }
    })
    return () => unsub()
  }, [])

  const redirectTo = useMemo(() => ({ pathname: '/login', search: `?next=${encodeURIComponent(location.pathname)}` }), [location.pathname])

  if (state.loading) return <div style={{ padding: 24 }}>Loading…</div>
  if (!state.authed) return <Navigate to={redirectTo} replace />
  if (!state.isAdmin) return <div style={{ padding: 24 }}>Unauthorized (admin only).</div>
  return children
}

