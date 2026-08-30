import React, { useEffect, useMemo, useState } from 'react'
import { collection, getCountFromServer, query, where } from 'firebase/firestore'
import { Activity, ArrowLeftRight, DollarSign, TrendingDown, TrendingUp, Users as UsersIcon } from 'lucide-react'
import { db } from '../../firebase/client'

function StatCard({ label, value, icon, trend, up }) {
  return (
    <div className="stat-card">
      <div className="stat-icon">{icon}</div>
      <div className="stat-label">{label}</div>
      <div className="stat-value">{value}</div>
      <div className={`stat-trend ${up ? 'trend-up' : 'trend-down'}`}>
        {up ? <TrendingUp size={14} /> : <TrendingDown size={14} />}
        {trend}
      </div>
    </div>
  )
}

export default function Dashboard() {
  const [loading, setLoading] = useState(true)
  const [counts, setCounts] = useState({ users: 0, tx: 0, withBalance: 0 })

  useEffect(() => {
    const run = async () => {
      setLoading(true)
      try {
        const usersCount = await getCountFromServer(collection(db, 'users'))
        const txCount = await getCountFromServer(collection(db, 'transactions'))
        const withBalanceCount = await getCountFromServer(query(collection(db, 'users'), where('balance', '>', 0)))
        setCounts({
          users: usersCount.data().count,
          tx: txCount.data().count,
          withBalance: withBalanceCount.data().count,
        })
      } finally {
        setLoading(false)
      }
    }
    run()
  }, [])

  const cards = useMemo(
    () => [
      { label: 'Total Users', value: counts.users, icon: <UsersIcon />, trend: 'Live', up: true },
      { label: 'Transactions', value: counts.tx, icon: <ArrowLeftRight />, trend: 'Live', up: true },
      { label: 'Users With Balance', value: counts.withBalance, icon: <DollarSign />, trend: 'Live', up: true },
      { label: 'System Activity', value: 'Normal', icon: <Activity />, trend: 'Stable', up: true },
    ],
    [counts]
  )

  return (
    <div className="animate-fade-in">
      <div className="header">
        <div className="welcome">
          <h1>Dashboard</h1>
          <p>Real-time overview (Firebase).</p>
        </div>
      </div>

      {loading ? (
        <div style={{ padding: 12 }}>Loading dashboard…</div>
      ) : (
        <>
          <div className="stats-grid">
            {cards.map((c) => (
              <StatCard key={c.label} {...c} />
            ))}
          </div>

          <div className="data-section">
            <div className="section-header">
              <h2 className="section-title">Notes</h2>
            </div>
            <p style={{ color: 'var(--text-muted)' }}>
              Add your Firestore collections: <code>users</code>, <code>transactions</code>, <code>companies</code>. Pages update in real time.
            </p>
          </div>
        </>
      )}
    </div>
  )
}

