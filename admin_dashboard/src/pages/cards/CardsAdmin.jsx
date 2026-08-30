import React from 'react'
import CollectionTablePage from '../shared/CollectionTablePage'

export default function CardsAdmin() {
  return (
    <CollectionTablePage
      title="Cards"
      description="Issued physical and virtual card records."
      collectionName="cards"
      columns={[
        { key: 'userId', label: 'User' },
        { key: 'type', label: 'Type' },
        { key: 'last4', label: 'Last 4' },
        { key: 'status', label: 'Status' },
        { key: 'createdAt', label: 'Created' },
      ]}
    />
  )
}
