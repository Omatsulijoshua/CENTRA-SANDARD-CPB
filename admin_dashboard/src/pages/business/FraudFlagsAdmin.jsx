import React, { useEffect, useState } from 'react'
import { apiRequest } from '../../utils/api'

export default function FraudFlagsAdmin() {
  const [flags, setFlags] = useState([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState('')
  const [actionLoading, setActionLoading] = useState(null)

  const fetchFlags = async () => {
    try {
      setLoading(true)
      const data = await apiRequest('/admin/fraud-flags')
      setFlags(data)
    } catch (err) {
      setError(err.message || 'Failed to load fraud flags')
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => {
    fetchFlags()
  }, [])

  const handleToggleResolve = async (id, resolved) => {
    setError('')
    setActionLoading(id)
    try {
      await apiRequest(`/admin/fraud-flags/${id}/resolve`, {
        method: 'PATCH',
        body: JSON.stringify({ resolved }),
      })
      await fetchFlags()
    } catch (err) {
      setError(err.message || 'Failed to update fraud flag status')
    } finally {
      setActionLoading(null)
    }
  }

  return (
    <div className="animate-fade-in">
      <div className="header">
        <div className="welcome">
          <h1>Fraud Risk & Flags</h1>
          <p>Monitor security violations, employee anomalies, and transaction limits bypasses.</p>
        </div>
      </div>

      {error && (
        <div style={{ padding: 12, background: '#fee2e2', color: '#ef4444', borderRadius: 8, marginBottom: 16 }}>
          {error}
        </div>
      )}

      <div className="data-section">
        <div className="section-header">
          <h2 className="section-title">Audit Flag Log</h2>
        </div>

        {loading ? (
          <div style={{ padding: 24, textAlign: 'center' }}>Loading flags...</div>
        ) : flags.length === 0 ? (
          <div style={{ padding: '3rem 1rem', textAlign: 'center', color: 'var(--text-muted)' }}>
            No security fraud flags detected.
          </div>
        ) : (
          <table>
            <thead>
              <tr>
                <th>Reason</th>
                <th>Severity</th>
                <th>Risk Score</th>
                <th>Date Logged</th>
                <th>Resolved</th>
                <th>Actions</th>
              </tr>
            </thead>
            <tbody>
              {flags.map((f) => (
                <tr key={f.id}>
                  <td style={{ fontWeight: 600 }}>{f.reason}</td>
                  <td>
                    <span className={`badge badge-${String(f.severity).toLowerCase()}`}>
                      {f.severity}
                    </span>
                  </td>
                  <td>
                    <span style={{ fontWeight: 700, color: f.score > 70 ? '#ef4444' : 'inherit' }}>
                      {f.score}
                    </span>
                  </td>
                  <td>{new Date(f.createdAt).toLocaleString()}</td>
                  <td>
                    <span className={`badge badge-${f.resolved ? 'active' : 'kyc-unverified'}`}>
                      {f.resolved ? 'Resolved' : 'Active Warning'}
                    </span>
                  </td>
                  <td>
                    <button
                      disabled={actionLoading === f.id}
                      onClick={() => handleToggleResolve(f.id, !f.resolved)}
                      className="btn"
                      style={{
                        padding: '4px 8px',
                        fontSize: '0.75rem',
                        background: f.resolved ? '#475569' : '#0284c7',
                        color: 'white',
                        border: 'none',
                      }}
                    >
                      {f.resolved ? 'Re-open' : 'Mark Resolved'}
                    </button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
      </div>
    </div>
  )
}
