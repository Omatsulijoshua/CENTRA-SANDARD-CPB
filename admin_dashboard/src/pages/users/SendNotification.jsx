import React, { useState } from 'react'
import { addDoc, collection, serverTimestamp } from 'firebase/firestore'
import { db } from '../../firebase/client'

export default function SendNotification() {
  const [title, setTitle] = useState('')
  const [body, setBody] = useState('')
  const [audience, setAudience] = useState('all')
  const [saving, setSaving] = useState(false)
  const [done, setDone] = useState('')

  const submit = async (e) => {
    e.preventDefault()
    setDone('')
    setSaving(true)
    try {
      await addDoc(collection(db, 'notifications'), {
        title,
        body,
        audience,
        createdAt: serverTimestamp(),
        status: 'queued',
      })
      setTitle('')
      setBody('')
      setAudience('all')
      setDone('Notification queued.')
    } finally {
      setSaving(false)
    }
  }

  return (
    <div className="animate-fade-in">
      <div className="header">
        <div className="welcome">
          <h1>Send Notification</h1>
          <p>Creates a notification document in Firestore (use Cloud Functions/FCM to deliver).</p>
        </div>
      </div>

      <div className="data-section">
        <form onSubmit={submit}>
          <div className="form-group">
            <label>Audience</label>
            <select className="form-input" value={audience} onChange={(e) => setAudience(e.target.value)}>
              <option value="all">All Users</option>
              <option value="kyc-unverified">KYC Unverified</option>
              <option value="with-balance">With Balance</option>
              <option value="banned">Banned</option>
            </select>
          </div>
          <div className="form-group">
            <label>Title</label>
            <input className="form-input" value={title} onChange={(e) => setTitle(e.target.value)} placeholder="Enter title" required />
          </div>
          <div className="form-group">
            <label>Message</label>
            <textarea className="form-input" style={{ minHeight: 120 }} value={body} onChange={(e) => setBody(e.target.value)} placeholder="Enter message" required />
          </div>
          <button disabled={saving} className="btn btn-primary" type="submit">
            {saving ? 'Submitting…' : 'Submit'}
          </button>
          {done && <div style={{ marginTop: 12, color: 'var(--accent)', fontWeight: 700 }}>{done}</div>}
        </form>
      </div>
    </div>
  )
}

