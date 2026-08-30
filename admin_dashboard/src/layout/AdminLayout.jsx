import React from 'react'
import { Routes, Route, Navigate } from 'react-router-dom'
import Sidebar from './Sidebar'
import Dashboard from '../pages/dashboard/Dashboard'
import CompanyList from '../pages/utility/CompanyList'
import BillCategories from '../pages/utility/BillCategories'
import ChargeSettings from '../pages/utility/ChargeSettings'
import UtilityBills from '../pages/utility/UtilityBills'
import UsersList from '../pages/users/UsersList'
import UserDetail from '../pages/users/UserDetail'
import SendNotification from '../pages/users/SendNotification'
import TransactionsByType from '../pages/transactions/TransactionsByType'
import EducationFee from '../pages/feature/EducationFee'
import Donations from '../pages/feature/Donations'
import VirtualCards from '../pages/feature/VirtualCards'
import RequestMoney from '../pages/feature/RequestMoney'
import UserAddMoney from '../pages/finance/UserAddMoney'
import CardsAdmin from '../pages/cards/CardsAdmin'
import CardOrdersAdmin from '../pages/cards/CardOrdersAdmin'
import LinkedBankCardsAdmin from '../pages/cards/LinkedBankCardsAdmin'
import NfcPaymentsAdmin from '../pages/cards/NfcPaymentsAdmin'
import ChildAccountsAdmin from '../pages/children/ChildAccountsAdmin'
import BannerAdsAdmin from '../pages/content/BannerAdsAdmin'
import PushNotificationsAdmin from '../pages/content/PushNotificationsAdmin'
import BusinessList from '../pages/business/BusinessList'
import FraudFlagsAdmin from '../pages/business/FraudFlagsAdmin'

export default function AdminLayout() {
  return (
    <div className="app-container">
      <Sidebar />
      <main className="main-content">
        <Routes>
          <Route path="/dashboard" element={<Dashboard />} />
          <Route path="/payments/:type" element={<TransactionsByType />} />

          <Route path="/utility/bills/:status" element={<UtilityBills />} />
          <Route path="/utility/companies" element={<CompanyList />} />
          <Route path="/utility/bill-categories" element={<BillCategories />} />
          <Route path="/utility/charge-settings" element={<ChargeSettings />} />

          <Route path="/users/:filter" element={<UsersList />} />
          <Route path="/users/detail/:userId" element={<UserDetail />} />
          <Route path="/users/send-notification" element={<SendNotification />} />

          <Route path="/donations" element={<Donations />} />
          <Route path="/education-fee" element={<EducationFee />} />
          <Route path="/virtual-cards" element={<VirtualCards />} />
          <Route path="/request-money" element={<RequestMoney />} />
          <Route path="/finance/user-add-money" element={<UserAddMoney />} />
          <Route path="/cards/all" element={<CardsAdmin />} />
          <Route path="/cards/orders" element={<CardOrdersAdmin />} />
          <Route path="/cards/linked-bank-cards" element={<LinkedBankCardsAdmin />} />
          <Route path="/cards/nfc-payments" element={<NfcPaymentsAdmin />} />
          <Route path="/children" element={<ChildAccountsAdmin />} />
          <Route path="/content/banners" element={<BannerAdsAdmin />} />
          <Route path="/content/push" element={<PushNotificationsAdmin />} />
          <Route path="/business/all" element={<BusinessList />} />
          <Route path="/business/fraud-flags" element={<FraudFlagsAdmin />} />

          <Route path="/settings" element={<div>Settings (coming soon)</div>} />
          <Route path="/" element={<Navigate to="/dashboard" replace />} />
          <Route path="*" element={<Navigate to="/dashboard" replace />} />
        </Routes>
      </main>
    </div>
  )
}
