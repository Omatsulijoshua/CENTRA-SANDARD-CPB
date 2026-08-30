import React from 'react'
import CollectionTablePage from '../shared/CollectionTablePage'

export default function RequestMoney() {
  return (
    <CollectionTablePage
      title="Request Money"
      description="Money request records and their current status."
      collectionName="moneyRequests"
      columns={[
        { key: 'requesterId', label: 'Requester' },
        { key: 'recipientId', label: 'Recipient' },
        { key: 'amount', label: 'Amount' },
        { key: 'status', label: 'Status' },
        { key: 'createdAt', label: 'Date' },
      ]}
    />
  )
}
