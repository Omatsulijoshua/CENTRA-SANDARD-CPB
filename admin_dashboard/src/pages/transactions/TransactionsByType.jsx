import React, { useEffect, useMemo, useState } from 'react'
import { Link, useParams } from 'react-router-dom'
import { collection, onSnapshot, orderBy, query, where } from 'firebase/firestore'
import { Search } from 'lucide-react'
import { db } from '../../firebase/client'

function label(type) {
  switch (type) {
    case 'send-money':
      return 'Manage Send Money'
    case 'cashout':
      return 'Manage Cash out'
    case 'payment':
      return 'Manage Payment'
    case 'bank-transfer':
      return 'Bank Transfer'
    case 'mobile-recharge':
      return 'Mobile Recharge'
    case 'airtime':
      return 'Manage Airtime'
    case 'microfinance':
      return 'Manage Microfinance'
    default:
      return 'Transactions'
  }
}

function txTypeFilter(type) {
  switch (type) {
    case 'send-money':
      return 'send_money'
    case 'cashout':
      return 'cashout'
    case 'payment':
      return 'payment'
    case 'bank-transfer':
      return 'bank_transfer'
    case 'mobile-recharge':
      return 'mobile_recharge'
    case 'airtime':
      return 'airtime'
    case 'microfinance':
      return 'microfinance'
    default:
      return null
  }
}

export default function TransactionsByType() {
  const { type = 'send-money' } = useParams()
  const [rows, setRows] = useState([])
  const [search, setSearch] = useState('')

  useEffect(() => {
    const base = collection(db, 'transactions')
    const f = txTypeFilter(type)
    const q = f ? query(base, where('type', '==', f), orderBy('createdAt', 'desc')) : query(base, orderBy('createdAt', 'desc'))
    const unsub = onSnapshot(q, (snap) => setRows(snap.docs.map((d) => ({ id: d.id, ...d.data() }))))
    return () => unsub()
  }, [type])

  const filtered = useMemo(() => {
    const s = search.trim().toLowerCase()
    if (!s) return rows
    return rows.filter((r) => {
      const hay = `${r.userId || ''} ${r.counterpartyAccount || ''} ${r.counterpartyName || ''} ${r.reference || ''}`.toLowerCase()
      return hay.includes(s)
    })
  }, [rows, search])

  return (
    <div className="animate-fade-in">
      <div className="header">
        <div className="welcome">
          <h1>{label(type)}</h1>
          <p>
            Realtime feed from <code>transactions</code>.
          </p>
        </div>
      </div>

      <div className="data-section">
        <div className="section-header" style={{ gap: 12 }}>
          <div className="table-search" style={{ maxWidth: 420 }}>
            <Search size={16} />
            <input value={search} onChange={(e) => setSearch(e.target.value)} placeholder="Search transactions…" />
          </div>
        </div>

        {filtered.length === 0 ? (
          <div style={{ padding: '3rem 1rem', textAlign: 'center', color: 'var(--text-muted)' }}>No data found.</div>
        ) : (
          <table>
            <thead>
              <tr>
                <th>Type</th>
                <th>User</th>
                <th>Counterparty</th>
                <th>Amount</th>
                <th>Date</th>
                <th style={{ width: 120 }}>Action</th>
              </tr>
            </thead>
            <tbody>
              {filtered.slice(0, 250).map((r) => (
                <tr key={r.id}>
                  <td style={{ fontWeight: 700 }}>{String(r.type || '—')}</td>
                  <td>
                    <div style={{ fontWeight: 700 }}>{String(r.userId || '—')}</div>
                    <div style={{ fontSize: '0.75rem', color: 'var(--text-muted)' }}>{String(r.direction || '')}</div>
                  </td>
                  <td>
                    <div style={{ fontWeight: 600 }}>{String(r.counterpartyName || '—')}</div>
                    <div style={{ fontSize: '0.8rem', color: 'var(--text-muted)' }}>{String(r.counterpartyAccount || '')}</div>
                  </td>
                  <td style={{ fontWeight: 800 }}>{Number(r.amount || 0).toLocaleString()}</td>
                  <td style={{ color: 'var(--text-muted)', fontSize: '0.85rem' }}>
                    {r.createdAt?.toDate ? r.createdAt.toDate().toLocaleString() : '—'}
                  </td>
                  <td>
                    <Link className="btn btn-outline" style={{ padding: '0.4rem 0.75rem' }} to={`/users/detail/${r.userId || ''}`}>
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

