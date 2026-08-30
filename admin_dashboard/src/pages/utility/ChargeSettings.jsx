import React, { useEffect, useState } from 'react'
import { doc, getDoc, setDoc } from 'firebase/firestore'
import { db } from '../../firebase/client'

const DEFAULTS = {
  sendMoneyCharge: 0,
  bankTransferCharge: 0,
  airtimeCharge: 0,
  utilityBillCharge: 0,
  educationFeeCharge: 0,
}

export default function ChargeSettings() {
  const [loading, setLoading] = useState(true)
  const [saving, setSaving] = useState(false)
  const [form, setForm] = useState(DEFAULTS)

  useEffect(() => {
    const run = async () => {
      setLoading(true)
      try {
        const snap = await getDoc(doc(db, 'config', 'chargeSettings'))
        if (snap.exists()) setForm({ ...DEFAULTS, ...snap.data() })
      } finally {
        setLoading(false)
      }
    }
    run()
  }, [])

  const save = async () => {
    setSaving(true)
    try {
      await setDoc(doc(db, 'config', 'chargeSettings'), form, { merge: true })
    } finally {
      setSaving(false)
    }
  }

  if (loading) return <div style={{ padding: 24 }}>Loading…</div>

  return (
    <div className="animate-fade-in">
      <div className="header">
        <div className="welcome">
          <h1>Charge Setting</h1>
          <p>Global charges stored in <code>config/chargeSettings</code>.</p>
        </div>
        <div className="actions">
          <button disabled={saving} className="btn btn-primary" onClick={save}>
            {saving ? 'Saving…' : 'Save'}
          </button>
        </div>
      </div>

      <div className="data-section">
        {Object.keys(DEFAULTS).map((key) => (
          <div key={key} className="form-group">
            <label>{key}</label>
            <input
              className="form-input"
              type="number"
              value={Number(form[key] || 0)}
              onChange={(e) => setForm((p) => ({ ...p, [key]: Number(e.target.value) }))}
            />
          </div>
        ))}
      </div>
    </div>
  )
}

