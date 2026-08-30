export function buildUserPredicate(filter) {
  return (u) => {
    const emailVerified = !!u.emailVerified
    const mobileVerified = !!u.mobileVerified
    const kycStatus = String(u.kycStatus || 'unverified')
    const banned = !!u.banned
    const deleted = !!u.deleted
    const balance = Number(u.balance || 0)

    switch (filter) {
      case 'active':
        return !deleted && !banned
      case 'email-unverified':
        return !emailVerified
      case 'mobile-unverified':
        return !mobileVerified
      case 'kyc-unverified':
        return kycStatus === 'unverified'
      case 'kyc-pending':
        return kycStatus === 'pending'
      case 'with-balance':
        return balance > 0
      case 'banned':
        return banned
      case 'deleted':
        return deleted
      case 'all':
      default:
        return true
    }
  }
}

export function labelForFilter(filter) {
  switch (filter) {
    case 'active':
      return 'Active Users'
    case 'email-unverified':
      return 'Email Unverified'
    case 'mobile-unverified':
      return 'Mobile Unverified'
    case 'kyc-unverified':
      return 'KYC Unverified'
    case 'kyc-pending':
      return 'KYC Pending'
    case 'with-balance':
      return 'Users With Balance'
    case 'banned':
      return 'Banned Users'
    case 'deleted':
      return 'Account Deleted Users'
    case 'all':
    default:
      return 'All Users'
  }
}

