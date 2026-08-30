import React, { useEffect, useMemo, useState } from 'react'
import { collection, onSnapshot, orderBy, query, where } from 'firebase/firestore'
import { Search } from 'lucide-react'
import { db } from '../../firebase/client'

export default function UserAddMoney() {
  const [rows, setRows] = useState([])
  const [search, setSearch] = useState('')

  useEffect(() => {
    const q = query(collection(db, 'transactions'), where('type', '==', 'add_money'), orderBy('createdAt', 'desc'))
    const unsub = onSnapshot(q, (snap) => setRows(snap.docs.map((d) => ({ id: d.id, ...d.data() }))))
    return () => unsub()
  }, [])

  const filtered = useMemo(() => {
    const s = search.trim().toLowerCase()
    if (!s) return rows
    return rows.filter((r) => `${r.userId || ''} ${r.reference || ''} ${r.provider || ''}`.toLowerCase().includes(s))
  }, [rows, search])

  return (
    <div className="animate-fade-in">
      <div className="header">
        <div className="welcome">
          <h1>User Add Money</h1>
          <p>
            Filtered from <code>transactions</code> where <code>type == add_money</code>.
          </p>
        </div>
      </div>
      <div className="data-section">
        <div className="section-header" style={{ gap: 12 }}>
          <div className="table-search" style={{ maxWidth: 420 }}>
            <Search size={16} />
            <input value={search} onChange={(e) => setSearch(e.target.value)} placeholder="Search…" />
          </div>
        </div>
        {filtered.length === 0 ? (
          <div style={{ padding: '3rem 1rem', textAlign: 'center', color: 'var(--text-muted)' }}>No data found.</div>
        ) : (
          <table>
            <thead>
              <tr>
                <th>User</th>
                <th>Amount</th>
                <th>Provider</th>
                <th>Date</th>
              </tr>
            </thead>
            <tbody>
              {filtered.slice(0, 250).map((r) => (
                <tr key={r.id}>
                  <td style={{ fontWeight: 700 }}>{String(r.userId || '—')}</td>
                  <td style={{ fontWeight: 800 }}>{Number(r.amount || 0).toLocaleString()}</td>
                  <td>{String(r.provider || '—')}</td>
                  <td style={{ color: 'var(--text-muted)', fontSize: '0.85rem' }}>
                    {r.createdAt?.toDate ? r.createdAt.toDate().toLocaleString() : '—'}
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

