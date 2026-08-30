import React, { useEffect, useMemo, useState } from 'react'
import { addDoc, collection, deleteDoc, doc, onSnapshot, orderBy, query, serverTimestamp, updateDoc } from 'firebase/firestore'
import { Plus, Search, Trash2 } from 'lucide-react'
import { db } from '../../firebase/client'

export default function BillCategories() {
  const [items, setItems] = useState([])
  const [search, setSearch] = useState('')
  const [creating, setCreating] = useState(false)

  useEffect(() => {
    const q = query(collection(db, 'billCategories'), orderBy('createdAt', 'desc'))
    const unsub = onSnapshot(q, (snap) => setItems(snap.docs.map((d) => ({ id: d.id, ...d.data() }))))
    return () => unsub()
  }, [])

  const filtered = useMemo(() => {
    const s = search.trim().toLowerCase()
    if (!s) return items
    return items.filter((it) => String(it.name || '').toLowerCase().includes(s))
  }, [items, search])

  const create = async () => {
    setCreating(true)
    try {
      await addDoc(collection(db, 'billCategories'), { name: 'New Category', status: 'active', createdAt: serverTimestamp() })
    } finally {
      setCreating(false)
    }
  }

  const updateField = async (id, patch) => updateDoc(doc(db, 'billCategories', id), patch)
  const remove = async (id) => deleteDoc(doc(db, 'billCategories', id))

  return (
    <div className="animate-fade-in">
      <div className="header">
        <div className="welcome">
          <h1>Bill Category</h1>
          <p>Utility bill categories (Firestore).</p>
        </div>
        <div className="actions">
          <button disabled={creating} className="btn btn-primary" onClick={create}>
            <Plus size={16} /> Add New
          </button>
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
          <div style={{ padding: '3rem 1rem', textAlign: 'center', color: 'var(--text-muted)' }}>No categories found.</div>
        ) : (
          <table>
            <thead>
              <tr>
                <th>Name</th>
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

