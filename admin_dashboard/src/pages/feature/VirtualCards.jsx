import React from 'react'
import CollectionTablePage from '../shared/CollectionTablePage'

export default function VirtualCards() {
  return (
    <CollectionTablePage
      title="Virtual Cards"
      description="Virtual card records across users."
      collectionName="virtualCards"
      columns={[
        { key: 'userId', label: 'User' },
        { key: 'cardName', label: 'Card' },
        { key: 'last4', label: 'Last 4' },
        { key: 'status', label: 'Status' },
        { key: 'createdAt', label: 'Created' },
      ]}
    />
  )
}
