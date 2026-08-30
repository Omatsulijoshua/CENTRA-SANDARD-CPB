import React, { useEffect, useMemo, useState } from 'react'
import { addDoc, collection, deleteDoc, doc, onSnapshot, orderBy, query, serverTimestamp, updateDoc } from 'firebase/firestore'
import { Plus, Search, Trash2 } from 'lucide-react'
import { db } from '../../firebase/client'

function EmptyState({ title, subtitle }) {
  return (
    <div style={{ padding: '3rem 1rem', textAlign: 'center', color: 'var(--text-muted)' }}>
      <div style={{ fontSize: 18, marginBottom: 8 }}>{title}</div>
      <div style={{ fontSize: 13 }}>{subtitle}</div>
    </div>
  )
}

export default function CompanyList() {
  const [items, setItems] = useState([])
  const [search, setSearch] = useState('')
  const [status, setStatus] = useState('all')
  const [creating, setCreating] = useState(false)

  useEffect(() => {
    const q = query(collection(db, 'companies'), orderBy('createdAt', 'desc'))
    const unsub = onSnapshot(q, (snap) => {
      setItems(snap.docs.map((d) => ({ id: d.id, ...d.data() })))
    })
    return () => unsub()
  }, [])

  const filtered = useMemo(() => {
    const s = search.trim().toLowerCase()
    return items.filter((it) => {
      const matchesSearch = !s || String(it.name || '').toLowerCase().includes(s) || String(it.category || '').toLowerCase().includes(s)
      const matchesStatus = status === 'all' || String(it.status || 'active') === status
      return matchesSearch && matchesStatus
    })
  }, [items, search, status])

  const createCompany = async () => {
    setCreating(true)
    try {
      await addDoc(collection(db, 'companies'), {
        name: 'New Company',
        category: 'Utility',
        charge: 0,
        status: 'active',
        createdAt: serverTimestamp(),
      })
    } finally {
      setCreating(false)
    }
  }

  const updateField = async (id, patch) => updateDoc(doc(db, 'companies', id), patch)
  const remove = async (id) => deleteDoc(doc(db, 'companies', id))

  return (
    <div className="animate-fade-in">
      <div className="header">
        <div className="welcome">
          <h1>Company List</h1>
          <p>Manage utility bill companies (Firestore).</p>
        </div>
        <div className="actions" style={{ display: 'flex', gap: 8 }}>
          <button disabled={creating} className="btn btn-primary" onClick={createCompany}>
            <Plus size={16} /> Add New
          </button>
        </div>
      </div>

      <div className="data-section">
        <div className="section-header" style={{ gap: 12 }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 10, flex: 1 }}>
            <div className="table-search">
              <Search size={16} />
              <input value={search} onChange={(e) => setSearch(e.target.value)} placeholder="Search…" />
            </div>
            <select className="table-select" value={status} onChange={(e) => setStatus(e.target.value)}>
              <option value="all">All</option>
              <option value="active">Active</option>
              <option value="inactive">Inactive</option>
            </select>
          </div>
        </div>

        {filtered.length === 0 ? (
          <EmptyState title="No data found" subtitle="Create a company or adjust your filters." />
        ) : (
          <table>
            <thead>
              <tr>
                <th>Name</th>
                <th>Category</th>
                <th>Charge</th>
                <th>Status</th>
                <th style={{ width: 96 }}>Action</th>
              </tr>
            </thead>
            <tbody>
              {filtered.map((row) => (
                <tr key={row.id}>
                  <td>
                    <input className="table-input" value={row.name || ''} onChange={(e) => updateField(row.id, { name: e.target.value })} />
                  </td>
                  <td>
                    <input
                      className="table-input"
                      value={row.category || ''}
                      onChange={(e) => updateField(row.id, { category: e.target.value })}
                    />
                  </td>
                  <td>
                    <input
                      className="table-input"
                      type="number"
                      value={Number(row.charge || 0)}
                      onChange={(e) => updateField(row.id, { charge: Number(e.target.value) })}
                    />
                  </td>
                  <td>
                    <select className="table-select" value={row.status || 'active'} onChange={(e) => updateField(row.id, { status: e.target.value })}>
                      <option value="active">Active</option>
                      <option value="inactive">Inactive</option>
                    </select>
                  </td>
                  <td>
                    <button className="btn btn-outline" style={{ padding: '0.4rem' }} onClick={() => remove(row.id)} title="Delete">
                      <Trash2 size={16} />
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

