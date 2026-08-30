import React from 'react'
import CollectionTablePage from '../shared/CollectionTablePage'

export default function CardOrdersAdmin() {
  return (
    <CollectionTablePage
      title="Card Orders"
      description="Physical card order requests."
      collectionName="cardOrders"
      columns={[
        { key: 'userId', label: 'User' },
        { key: 'cardType', label: 'Card Type' },
        { key: 'deliveryAddress', label: 'Delivery Address' },
        { key: 'status', label: 'Status' },
        { key: 'createdAt', label: 'Date' },
      ]}
    />
  )
}
