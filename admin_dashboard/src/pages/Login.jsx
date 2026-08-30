import React, { useMemo, useState } from 'react'
import { useNavigate, useSearchParams } from 'react-router-dom'
import { ShieldCheck } from 'lucide-react'
import { signInWithEmailAndPassword } from 'firebase/auth'
import { auth } from '../firebase/client'

export default function Login() {
  const [params] = useSearchParams()
  const navigate = useNavigate()
  const nextPath = useMemo(() => params.get('next') || '/', [params])

  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [error, setError] = useState('')
  const [loading, setLoading] = useState(false)

  const handleLogin = async (e) => {
    e.preventDefault()
    setError('')
    setLoading(true)
    try {
      await signInWithEmailAndPassword(auth, email, password)
      navigate(nextPath, { replace: true })
    } catch (err) {
      setError(err?.message || 'Login failed')
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className="login-container">
      <div className="login-card animate-fade-in">
        <div className="logo" style={{ justifyContent: 'center', marginBottom: '2rem' }}>
          <ShieldCheck size={40} color="#3b82f6" />
          <span>CENTRA</span> ADMIN
        </div>
        <h2 style={{ textAlign: 'center', marginBottom: '1.5rem' }}>Secure Login</h2>
        {error && <p style={{ color: '#ef4444', textAlign: 'center', marginBottom: '1rem', fontSize: '0.875rem' }}>{error}</p>}
        <form onSubmit={handleLogin}>
          <div className="form-group">
            <label>Email Address</label>
            <input
              type="email"
              className="form-input"
              placeholder="admin@bank.com"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              required
            />
          </div>
          <div className="form-group">
            <label>Password</label>
            <input
              type="password"
              className="form-input"
              placeholder="••••••••"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              required
            />
          </div>
          <button disabled={loading} type="submit" className="btn btn-primary" style={{ width: '100%', justifyContent: 'center', marginTop: '1rem' }}>
            {loading ? 'Signing in…' : 'Enter Dashboard'}
          </button>
        </form>
      </div>
    </div>
  )
}

