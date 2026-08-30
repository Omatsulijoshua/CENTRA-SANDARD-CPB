import React, { useEffect, useMemo, useState } from 'react'
import { addDoc, collection, onSnapshot, orderBy, query, serverTimestamp } from 'firebase/firestore'
import { Send } from 'lucide-react'
import { db } from '../../firebase/client'

export default function PushNotificationsAdmin() {
  const [title, setTitle] = useState('')
  const [body, setBody] = useState('')
  const [audience, setAudience] = useState('all')
  const [rows, setRows] = useState([])
  useEffect(() => {
    const q = query(collection(db, 'notifications'), orderBy('createdAt', 'desc'))
    const unsub = onSnapshot(q, (snap) => setRows(snap.docs.map((d) => ({ id: d.id, ...d.data() }))))
    return () => unsub()
  }, [])
  const recent = useMemo(() => rows.slice(0, 20), [rows])
  const submit = async (e) => {
    e.preventDefault()
    await addDoc(collection(db, 'notifications'), { title, body, audience, status: 'queued', createdAt: serverTimestamp() })
    setTitle('')
    setBody('')
    setAudience('all')
  }

  return (
    <div className="animate-fade-in">
      <div className="header"><div className="welcome"><h1>Push Notification</h1><p>Queue notifications for Cloud Functions / FCM delivery.</p></div></div>
      <div className="grid-2">
        <div className="data-section">
          <form onSubmit={submit}>
            <div className="form-group"><label>Audience</label><select className="form-input" value={audience} onChange={(e) => setAudience(e.target.value)}><option value="all">All users</option><option value="parents">Parents</option><option value="children">Children</option><option value="kyc-unverified">KYC unverified</option></select></div>
            <div className="form-group"><label>Title</label><input className="form-input" value={title} onChange={(e) => setTitle(e.target.value)} required /></div>
            <div className="form-group"><label>Message</label><textarea className="form-input" value={body} onChange={(e) => setBody(e.target.value)} required style={{ minHeight: 120 }} /></div>
            <button className="btn btn-primary" type="submit"><Send size={16} /> Queue</button>
          </form>
        </div>
        <div className="data-section">
          <div className="section-header"><h2 className="section-title">Recent</h2></div>
          {recent.map((n) => <div key={n.id} className="overview-item" style={{ marginBottom: 10 }}><div className="v">{n.title}</div><div className="k">{n.audience} · {n.status || 'queued'}</div></div>)}
        </div>
      </div>
    </div>
  )
}

