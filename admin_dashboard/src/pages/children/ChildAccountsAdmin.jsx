import React, { useEffect, useMemo, useState } from 'react'
import { collection, doc, onSnapshot, orderBy, query, updateDoc } from 'firebase/firestore'
import { Search } from 'lucide-react'
import { db } from '../../firebase/client'

export default function ChildAccountsAdmin() {
  const [rows, setRows] = useState([])
  const [search, setSearch] = useState('')
  useEffect(() => {
    const q = query(collection(db, 'children'), orderBy('createdAt', 'desc'))
    const unsub = onSnapshot(q, (snap) => setRows(snap.docs.map((d) => ({ id: d.id, ...d.data() }))))
    return () => unsub()
  }, [])
  const filtered = useMemo(() => {
    const s = search.trim().toLowerCase()
    if (!s) return rows
    return rows.filter((r) => `${r.name || ''} ${r.username || ''} ${r.parentUserId || ''}`.toLowerCase().includes(s))
  }, [rows, search])
  const setStatus = (id, status) => updateDoc(doc(db, 'children', id), { status, updatedAt: new Date() })

  return (
    <div className="animate-fade-in">
      <div className="header"><div className="welcome"><h1>Child Accounts</h1><p>Parent-linked simple accounts and limits.</p></div></div>
      <div className="data-section">
        <div className="section-header"><div className="table-search"><Search size={16} /><input value={search} onChange={(e) => setSearch(e.target.value)} placeholder="Search child accounts..." /></div></div>
        {filtered.length === 0 ? <div style={{ padding: '3rem', textAlign: 'center', color: 'var(--text-muted)' }}>No child accounts found.</div> : (
          <table><thead><tr><th>Child</th><th>Parent</th><th>Balance</th><th>Daily Limit</th><th>Card Limit</th><th>Status</th></tr></thead><tbody>
            {filtered.map((r) => <tr key={r.id}><td><div style={{ fontWeight: 800 }}>{r.name || '-'}</div><div style={{ color: 'var(--text-muted)', fontSize: 12 }}>{r.username || '-'}</div></td><td>{r.parentUserId || '-'}</td><td>{Number(r.balance || 0).toLocaleString()}</td><td>{Number(r.dailyLimit || 0).toLocaleString()}</td><td>{Number(r.cardLimit || 0).toLocaleString()}</td><td><select className="table-select" value={r.status || 'active'} onChange={(e) => setStatus(r.id, e.target.value)}><option value="active">active</option><option value="paused">paused</option><option value="closed">closed</option></select></td></tr>)}
          </tbody></table>
        )}
      </div>
    </div>
  )
}

