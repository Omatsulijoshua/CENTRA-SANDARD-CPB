import React, { useEffect, useMemo, useState } from 'react'
import { useParams } from 'react-router-dom'
import { doc, onSnapshot, updateDoc, increment, addDoc, collection, serverTimestamp } from 'firebase/firestore'
import { db } from '../../firebase/client'

function ActionButton({ variant = 'outline', children, ...props }) {
  const cls = variant === 'primary' ? 'btn btn-primary' : 'btn btn-outline'
  return (
    <button className={cls} {...props}>
      {children}
    </button>
  )
}

function Modal({ title, open, onClose, children }) {
  if (!open) return null
  return (
    <div className="modal-backdrop" onMouseDown={onClose}>
      <div className="modal" onMouseDown={(e) => e.stopPropagation()}>
        <div className="modal-header">
          <div style={{ fontWeight: 700 }}>{title}</div>
          <button className="modal-close" onClick={onClose}>
            ×
          </button>
        </div>
        <div className="modal-body">{children}</div>
      </div>
    </div>
  )
}

export default function UserDetail() {
  const { userId } = useParams()
  const [user, setUser] = useState(null)
  const [loading, setLoading] = useState(true)
  const [showAddBalance, setShowAddBalance] = useState(false)
  const [amount, setAmount] = useState('')
  const [remark, setRemark] = useState('')

  useEffect(() => {
    const unsub = onSnapshot(doc(db, 'users', userId), (snap) => {
      setUser(snap.exists() ? { id: snap.id, ...snap.data() } : null)
      setLoading(false)
    })
    return () => unsub()
  }, [userId])

  const totals = useMemo(() => {
    const base = {
      sendMoney: Number(user?.totals?.sendMoney || 0),
      payment: Number(user?.totals?.payment || 0),
      mobileRecharge: Number(user?.totals?.mobileRecharge || 0),
      bankTransfer: Number(user?.totals?.bankTransfer || 0),
      microfinance: Number(user?.totals?.microfinance || 0),
      donation: Number(user?.totals?.donation || 0),
      utilityBill: Number(user?.totals?.utilityBill || 0),
      educationFee: Number(user?.totals?.educationFee || 0),
    }
    return base
  }, [user])

  const toggleFlag = async (field) => {
    await updateDoc(doc(db, 'users', userId), { [field]: !user?.[field] })
  }

  const submitBalance = async () => {
    const n = Number(amount)
    if (!Number.isFinite(n) || n <= 0) return
    await updateDoc(doc(db, 'users', userId), { balance: increment(n) })
    await addDoc(collection(db, 'transactions'), {
      type: 'admin_credit',
      userId,
      amount: n,
      remark: remark || '',
      createdAt: serverTimestamp(),
    })
    setAmount('')
    setRemark('')
    setShowAddBalance(false)
  }

  if (loading) return <div style={{ padding: 24 }}>Loading…</div>
  if (!user) return <div style={{ padding: 24 }}>User not found.</div>

  return (
    <div className="animate-fade-in">
      <div className="header">
        <div className="welcome">
          <h1>User Detail - {user.username || user.name || user.id}</h1>
          <p>Admin actions + overview (Firestore).</p>
        </div>
        <div className="actions" style={{ display: 'flex', gap: 8, flexWrap: 'wrap' }}>
          <ActionButton variant="primary" onClick={() => setShowAddBalance(true)}>
            + Balance
          </ActionButton>
          <ActionButton onClick={() => toggleFlag('banned')}>{user.banned ? 'Unban User' : 'Ban User'}</ActionButton>
        </div>
      </div>

      <div className="stats-grid">
        {[
          ['Total Send Money', totals.sendMoney],
          ['Total Payment', totals.payment],
          ['Total Mobile Recharge', totals.mobileRecharge],
          ['Total Bank Transfer', totals.bankTransfer],
          ['Total Microfinance', totals.microfinance],
          ['Total Donation', totals.donation],
          ['Total Utility Bill', totals.utilityBill],
          ['Total Education Fee', totals.educationFee],
        ].map(([label, value]) => (
          <div key={label} className="stat-card" style={{ minHeight: 110 }}>
            <div className="stat-label">{label}</div>
            <div className="stat-value">{Number(value).toLocaleString()} NGN</div>
          </div>
        ))}
      </div>

      <div className="grid-2">
        <div className="data-section">
          <div className="section-header">
            <h2 className="section-title">Profile</h2>
          </div>
          <div className="kv-grid">
            <div className="kv">
              <div className="k">Name</div>
              <div className="v">{user.name || '—'}</div>
            </div>
            <div className="kv">
              <div className="k">Email</div>
              <div className="v">{user.email || '—'}</div>
            </div>
            <div className="kv">
              <div className="k">Mobile</div>
              <div className="v">{user.phone || '—'}</div>
            </div>
            <div className="kv">
              <div className="k">Country</div>
              <div className="v">{user.country || '—'}</div>
            </div>
            <div className="kv">
              <div className="k">Balance</div>
              <div className="v">{Number(user.balance || 0).toLocaleString()} NGN</div>
            </div>
            <div className="kv">
              <div className="k">KYC</div>
              <div className="v">{String(user.kycStatus || 'unverified')}</div>
            </div>
          </div>

          <div className="toggle-row">
            <label className="toggle">
              <input type="checkbox" checked={!!user.emailVerified} onChange={() => toggleFlag('emailVerified')} />
              <span>Email Verification</span>
            </label>
            <label className="toggle">
              <input type="checkbox" checked={!!user.mobileVerified} onChange={() => toggleFlag('mobileVerified')} />
              <span>Mobile Verification</span>
            </label>
            <label className="toggle">
              <input
                type="checkbox"
                checked={String(user.kycStatus || '') === 'verified'}
                onChange={() => updateDoc(doc(db, 'users', userId), { kycStatus: 'verified' })}
              />
              <span>KYC Verification</span>
            </label>
          </div>
        </div>

        <div className="data-section">
          <div className="section-header">
            <h2 className="section-title">Financial Overview</h2>
          </div>
          <div className="overview-grid">
            <div className="overview-item">
              <div className="k">Balance</div>
              <div className="v">{Number(user.balance || 0).toLocaleString()} NGN</div>
            </div>
            <div className="overview-item">
              <div className="k">Total Add Money</div>
              <div className="v">{Number(user.totals?.addMoney || 0).toLocaleString()} NGN</div>
            </div>
            <div className="overview-item">
              <div className="k">Total CashOut</div>
              <div className="v">{Number(user.totals?.cashOut || 0).toLocaleString()} NGN</div>
            </div>
            <div className="overview-item">
              <div className="k">Total Transactions</div>
              <div className="v">{Number(user.totals?.transactions || 0).toLocaleString()}</div>
            </div>
          </div>
        </div>
      </div>

      <Modal title="Add Balance" open={showAddBalance} onClose={() => setShowAddBalance(false)}>
        <div className="form-group">
          <label>Amount</label>
          <input className="form-input" value={amount} onChange={(e) => setAmount(e.target.value)} placeholder="0" />
        </div>
        <div className="form-group">
          <label>Remark</label>
          <textarea
            className="form-input"
            style={{ minHeight: 92 }}
            value={remark}
            onChange={(e) => setRemark(e.target.value)}
            placeholder="Enter remark"
          />
        </div>
        <div style={{ display: 'flex', justifyContent: 'flex-end', gap: 8 }}>
          <button className="btn btn-outline" onClick={() => setShowAddBalance(false)}>
            Close
          </button>
          <button className="btn btn-primary" onClick={submitBalance}>
            Submit
          </button>
        </div>
      </Modal>
    </div>
  )
}

