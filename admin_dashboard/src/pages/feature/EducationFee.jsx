import React from 'react'
import CollectionTablePage from '../shared/CollectionTablePage'

export default function EducationFee() {
  return (
    <CollectionTablePage
      title="Education Fee"
      description="School and education payment records."
      collectionName="educationFees"
      columns={[
        { key: 'userId', label: 'User' },
        { key: 'studentName', label: 'Student' },
        { key: 'schoolName', label: 'School' },
        { key: 'amount', label: 'Amount' },
        { key: 'status', label: 'Status' },
        { key: 'createdAt', label: 'Date' },
      ]}
    />
  )
}
