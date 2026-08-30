import React from 'react'
import CollectionTablePage from '../shared/CollectionTablePage'

export default function Donations() {
  return (
    <CollectionTablePage
      title="Donations"
      description="Donation payment activity from Firestore."
      collectionName="donations"
      columns={[
        { key: 'userId', label: 'User' },
        { key: 'amount', label: 'Amount' },
        { key: 'organization', label: 'Organization' },
        { key: 'status', label: 'Status' },
        { key: 'createdAt', label: 'Date' },
      ]}
    />
  )
}
