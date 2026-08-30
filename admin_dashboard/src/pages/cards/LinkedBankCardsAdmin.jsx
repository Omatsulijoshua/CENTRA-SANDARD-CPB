import React from 'react'
import CollectionTablePage from '../shared/CollectionTablePage'

export default function LinkedBankCardsAdmin() {
  return (
    <CollectionTablePage
      title="Linked Bank Cards"
      description="External bank cards linked to user accounts."
      collectionName="linkedBankCards"
      columns={[
        { key: 'userId', label: 'User' },
        { key: 'bankName', label: 'Bank' },
        { key: 'last4', label: 'Last 4' },
        { key: 'active', label: 'Active' },
        { key: 'createdAt', label: 'Linked' },
      ]}
    />
  )
}
