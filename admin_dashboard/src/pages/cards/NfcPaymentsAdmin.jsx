import React from 'react'
import CollectionTablePage from '../shared/CollectionTablePage'

export default function NfcPaymentsAdmin() {
  return (
    <CollectionTablePage
      title="NFC Payments"
      description="Tap-to-pay transaction records."
      collectionName="nfcPayments"
      columns={[
        { key: 'userId', label: 'User' },
        { key: 'merchant', label: 'Merchant' },
        { key: 'amount', label: 'Amount' },
        { key: 'status', label: 'Status' },
        { key: 'createdAt', label: 'Date' },
      ]}
    />
  )
}
