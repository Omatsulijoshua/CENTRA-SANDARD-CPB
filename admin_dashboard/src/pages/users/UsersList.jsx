import React, { useEffect, useMemo, useState } from 'react'
import { Link, useParams } from 'react-router-dom'
import { collection, onSnapshot, orderBy, query } from 'firebase/firestore'
import { Search } from 'lucide-react'
import { db } from '../../firebase/client'
import { buildUserPredicate, labelForFilter } from './userFilters'

export default function UsersList() {
  const { filter = 'active' } = useParams()
  const [items, setItems] = useState([])
  const [search, setSearch] = useState('')

  useEffect(() => {
    const q = query(collection(db, 'users'), orderBy('createdAt', 'desc'))
    const unsub = onSnapshot(q, (snap) => {
      setItems(snap.docs.map((d) => ({ id: d.id, ...d.data() })))
    })
    return () => unsub()
  }, [])

  const filtered = useMemo(() => {
    const predicate = buildUserPredicate(filter)
    const s = search.trim().toLowerCase()
    return items
      .filter(predicate)
      .filter((u) => {
        if (!s) return true
        const hay = `${u.name || ''} ${u.email || ''} ${u.phone || ''} ${u.username || ''}`.toLowerCase()
        return hay.includes(s)
      })
  }, [items, filter, search])

  return (
    <div className="animate-fade-in">
      <div className="header">
        <div className="welcome">
          <h1>{labelForFilter(filter)}</h1>
          <p>Realtime users list (Firestore).</p>
        </div>
      </div>

      <div className="data-section">
        <div className="section-header" style={{ gap: 12 }}>
          <div className="table-search" style={{ maxWidth: 420 }}>
            <Search size={16} />
            <input value={search} onChange={(e) => setSearch(e.target.value)} placeholder="Search users…" />
          </div>
        </div>

        {filtered.length === 0 ? (
          <div style={{ padding: '3rem 1rem', textAlign: 'center', color: 'var(--text-muted)' }}>No users found.</div>
        ) : (
          <table>
            <thead>
              <tr>
                <th>User</th>
                <th>Email / Mobile</th>
                <th>Joined At</th>
                <th>Balance</th>
                <th style={{ width: 120 }}>Action</th>
              </tr>
            </thead>
            <tbody>
              {filtered.map((u) => (
                <tr key={u.id}>
                  <td>
                    <div style={{ fontWeight: 600 }}>{u.name || u.username || '—'}</div>
                    <div style={{ fontSize: '0.75rem', color: 'var(--text-muted)' }}>{u.username ? `@${u.username}` : ''}</div>
                  </td>
                  <td>
                    <div style={{ fontSize: '0.875rem' }}>{u.email || '—'}</div>
                    <div style={{ fontSize: '0.8rem', color: 'var(--text-muted)' }}>{u.phone || '—'}</div>
                  </td>
                  <td style={{ color: 'var(--text-muted)', fontSize: '0.85rem' }}>
                    {u.createdAt?.toDate ? u.createdAt.toDate().toLocaleString() : '—'}
                  </td>
                  <td style={{ fontWeight: 700 }}>{Number(u.balance || 0).toLocaleString()}</td>
                  <td>
                    <Link className="btn btn-outline" style={{ padding: '0.4rem 0.75rem' }} to={`/users/detail/${u.id}`}>
                      Details
                    </Link>
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

