import React, { useEffect, useMemo, useState } from 'react'
import { addDoc, collection, doc, onSnapshot, orderBy, query, serverTimestamp, updateDoc } from 'firebase/firestore'
import { Plus, Search } from 'lucide-react'
import { db } from '../../firebase/client'

export default function BannerAdsAdmin() {
  const [rows, setRows] = useState([])
  const [search, setSearch] = useState('')
  useEffect(() => {
    const q = query(collection(db, 'appBanners'), orderBy('priority', 'desc'))
    const unsub = onSnapshot(q, (snap) => setRows(snap.docs.map((d) => ({ id: d.id, ...d.data() }))))
    return () => unsub()
  }, [])
  const filtered = useMemo(() => {
    const s = search.trim().toLowerCase()
    if (!s) return rows
    return rows.filter((r) => `${r.title || ''} ${r.subtitle || ''}`.toLowerCase().includes(s))
  }, [rows, search])
  const create = () => addDoc(collection(db, 'appBanners'), { title: 'New banner', subtitle: '', imageUrl: '', actionUrl: '', active: true, priority: 0, createdAt: serverTimestamp(), updatedAt: serverTimestamp() })
  const update = (id, patch) => updateDoc(doc(db, 'appBanners', id), { ...patch, updatedAt: new Date() })

  return (
    <div className="animate-fade-in">
      <div className="header"><div className="welcome"><h1>Banner Ads</h1><p>App home carousel banners.</p></div><button className="btn btn-primary" onClick={create}><Plus size={16} /> Add New</button></div>
      <div className="data-section">
        <div className="section-header"><div className="table-search"><Search size={16} /><input value={search} onChange={(e) => setSearch(e.target.value)} placeholder="Search banners..." /></div></div>
        {filtered.length === 0 ? <div style={{ padding: '3rem', textAlign: 'center', color: 'var(--text-muted)' }}>No banners found.</div> : (
          <table><thead><tr><th>Title</th><th>Subtitle</th><th>Image URL</th><th>Priority</th><th>Active</th></tr></thead><tbody>
            {filtered.map((r) => <tr key={r.id}><td><input className="table-input" value={r.title || ''} onChange={(e) => update(r.id, { title: e.target.value })} /></td><td><input className="table-input" value={r.subtitle || ''} onChange={(e) => update(r.id, { subtitle: e.target.value })} /></td><td><input className="table-input" value={r.imageUrl || ''} onChange={(e) => update(r.id, { imageUrl: e.target.value })} /></td><td><input className="table-input" type="number" value={Number(r.priority || 0)} onChange={(e) => update(r.id, { priority: Number(e.target.value) })} /></td><td><input type="checkbox" checked={!!r.active} onChange={(e) => update(r.id, { active: e.target.checked })} /></td></tr>)}
          </tbody></table>
        )}
      </div>
    </div>
  )
}

