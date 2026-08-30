import React, { useEffect, useMemo, useState } from 'react'
import { collection, onSnapshot, orderBy, query } from 'firebase/firestore'
import { Search } from 'lucide-react'
import { db } from '../../firebase/client'

function formatValue(value) {
  if (value?.toDate) return value.toDate().toLocaleString()
  if (typeof value === 'number') return value.toLocaleString()
  if (typeof value === 'boolean') return value ? 'Yes' : 'No'
  if (value == null || value === '') return '-'
  if (typeof value === 'object') return JSON.stringify(value)
  return String(value)
}

export default function CollectionTablePage({ title, description, collectionName, orderField = 'createdAt', columns }) {
  const [rows, setRows] = useState([])
  const [search, setSearch] = useState('')

  useEffect(() => {
    const q = query(collection(db, collectionName), orderBy(orderField, 'desc'))
    const unsub = onSnapshot(q, (snap) => setRows(snap.docs.map((doc) => ({ id: doc.id, ...doc.data() }))))
    return () => unsub()
  }, [collectionName, orderField])

  const filtered = useMemo(() => {
    const value = search.trim().toLowerCase()
    if (!value) return rows
    return rows.filter((row) => columns.some((column) => formatValue(row[column.key]).toLowerCase().includes(value)))
  }, [columns, rows, search])

  return (
    <div className="animate-fade-in">
      <div className="header">
        <div className="welcome">
          <h1>{title}</h1>
          <p>{description}</p>
        </div>
      </div>
      <div className="data-section">
        <div className="section-header">
          <div className="table-search" style={{ maxWidth: 420 }}>
            <Search size={16} />
            <input value={search} onChange={(event) => setSearch(event.target.value)} placeholder="Search records..." />
          </div>
        </div>
        {filtered.length === 0 ? (
          <div style={{ padding: '3rem 1rem', textAlign: 'center', color: 'var(--text-muted)' }}>No data found.</div>
        ) : (
          <table>
            <thead>
              <tr>
                {columns.map((column) => (
                  <th key={column.key}>{column.label}</th>
                ))}
              </tr>
            </thead>
            <tbody>
              {filtered.slice(0, 250).map((row) => (
                <tr key={row.id}>
                  {columns.map((column, index) => (
                    <td key={column.key} style={index === 0 ? { fontWeight: 700 } : undefined}>
                      {formatValue(row[column.key])}
                    </td>
                  ))}
                </tr>
              ))}
            </tbody>
          </table>
        )}
      </div>
    </div>
  )
}
