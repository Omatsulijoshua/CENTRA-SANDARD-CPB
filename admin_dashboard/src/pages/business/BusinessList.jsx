import React, { useEffect, useState } from 'react'
import { apiRequest } from '../../utils/api'

export default function BusinessList() {
  const [businesses, setBusinesses] = useState([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState('')
  const [actionLoading, setActionLoading] = useState(null)

  const fetchBusinesses = async () => {
    try {
      setLoading(true)
      const data = await apiRequest('/admin/businesses')
      setBusinesses(data)
    } catch (err) {
      setError(err.message || 'Failed to load businesses')
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => {
    fetchBusinesses()
  }, [])

  const handleUpdateKyc = async (id, status) => {
    setError('')
    setActionLoading(id)
    try {
      await apiRequest(`/admin/businesses/${id}/kyc`, {
        method: 'PATCH',
        body: JSON.stringify({ status }),
      })
      // Refresh list
      await fetchBusinesses()
    } catch (err) {
      setError(err.message || 'Failed to update KYC status')
    } finally {
      setActionLoading(null)
    }
  }

  return (
    <div className="animate-fade-in">
      <div className="header">
        <div className="welcome">
          <h1>Business Management</h1>
          <p>Verify SME profiles, tax credentials, and CAC registrations.</p>
        </div>
      </div>

      {error && (
        <div style={{ padding: 12, background: '#fee2e2', color: '#ef4444', borderRadius: 8, marginBottom: 16 }}>
          {error}
        </div>
      )}

      <div className="data-section">
        <div className="section-header">
          <h2 className="section-title">All Registered Businesses</h2>
        </div>

        {loading ? (
          <div style={{ padding: 24, textLight: 'center' }}>Loading businesses...</div>
        ) : businesses.length === 0 ? (
          <div style={{ padding: '3rem 1rem', textAlign: 'center', color: 'var(--text-muted)' }}>
            No business accounts found.
          </div>
        ) : (
          <table>
            <thead>
              <tr>
                <th>Business Name</th>
                <th>Category</th>
                <th>Owner Email</th>
                <th>CAC Number</th>
                <th>Tax ID</th>
                <th>KYC Status</th>
                <th>Account Status</th>
                <th>Actions</th>
              </tr>
            </thead>
            <tbody>
              {businesses.map((b) => (
                <tr key={b.id}>
                  <td style={{ fontWeight: 700 }}>{b.name}</td>
                  <td>{b.category || '-'}</td>
                  <td>{b.owner?.email || 'N/A'}</td>
                  <td><code>{b.cacNumber || '-'}</code></td>
                  <td><code>{b.taxId || '-'}</code></td>
                  <td>
                    <span className={`badge badge-${String(b.kycStatus).toLowerCase()}`}>
                      {b.kycStatus}
                    </span>
                  </td>
                  <td>
                    <span className={`badge badge-${String(b.status).toLowerCase()}`}>
                      {b.status}
                    </span>
                  </td>
                  <td>
                    <div style={{ display: 'flex', gap: 8 }}>
                      {b.kycStatus !== 'APPROVED' && (
                        <button
                          disabled={actionLoading === b.id}
                          onClick={() => handleUpdateKyc(b.id, 'APPROVED')}
                          className="btn btn-primary"
                          style={{ padding: '4px 8px', fontSize: '0.75rem' }}
                        >
                          Approve
                        </button>
                      )}
                      {b.kycStatus !== 'REJECTED' && (
                        <button
                          disabled={actionLoading === b.id}
                          onClick={() => handleUpdateKyc(b.id, 'REJECTED')}
                          className="btn"
                          style={{ padding: '4px 8px', fontSize: '0.75rem', background: '#dc2626', color: 'white' }}
                        >
                          Reject
                        </button>
                      )}
                    </div>
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
