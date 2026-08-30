import React, { useMemo, useState } from 'react'
import { Link, useLocation } from 'react-router-dom'
import {
  Bell,
  Building2,
  Baby,
  ChevronDown,
  CreditCard,
  HandCoins,
  Landmark,
  LayoutDashboard,
  LogOut,
  Radio,
  ReceiptText,
  Settings,
  ShieldCheck,
  Smartphone,
  Ticket,
  Users,
  Wallet,
} from 'lucide-react'
import { signOut } from 'firebase/auth'
import { auth } from '../firebase/client'

function NavLink({ to, icon, label, exact }) {
  const location = useLocation()
  const isActive = exact ? location.pathname === to : location.pathname.startsWith(to)
  return (
    <Link to={to} className={`nav-item ${isActive ? 'active' : ''}`}>
      {icon}
      {label}
    </Link>
  )
}

function Group({ title, icon, children, defaultOpen = false }) {
  const [open, setOpen] = useState(defaultOpen)
  return (
    <div className="nav-group">
      <button type="button" className="nav-group-btn" onClick={() => setOpen((v) => !v)}>
        <span className="nav-group-left">
          {icon}
          {title}
        </span>
        <ChevronDown size={16} className={`nav-group-chevron ${open ? 'open' : ''}`} />
      </button>
      {open && <div className="nav-group-children">{children}</div>}
    </div>
  )
}

export default function Sidebar() {
  const location = useLocation()
  const defaultOpenUsers = useMemo(() => location.pathname.startsWith('/users'), [location.pathname])
  const defaultOpenUtility = useMemo(() => location.pathname.startsWith('/utility'), [location.pathname])
  const defaultOpenPayments = useMemo(() => location.pathname.startsWith('/payments'), [location.pathname])
  const defaultOpenFinance = useMemo(() => location.pathname.startsWith('/finance'), [location.pathname])
  const defaultOpenCards = useMemo(() => location.pathname.startsWith('/cards'), [location.pathname])
  const defaultOpenContent = useMemo(() => location.pathname.startsWith('/content'), [location.pathname])

  return (
    <div className="sidebar">
      <div className="logo">
        <ShieldCheck size={32} color="#3b82f6" />
        <span>CENTRA</span> ADMIN
      </div>

      <div className="nav-links">
        <NavLink to="/dashboard" exact icon={<LayoutDashboard size={20} />} label="Dashboard" />

        <Group title="Payments" icon={<Wallet size={18} />} defaultOpen={defaultOpenPayments}>
          <NavLink to="/payments/send-money" icon={<HandCoins size={18} />} label="Manage Send Money" />
          <NavLink to="/payments/cashout" icon={<Wallet size={18} />} label="Manage Cash out" />
          <NavLink to="/payments/payment" icon={<CreditCard size={18} />} label="Manage Payment" />
          <NavLink to="/payments/bank-transfer" icon={<Landmark size={18} />} label="Bank Transfer" />
          <NavLink to="/payments/mobile-recharge" icon={<Smartphone size={18} />} label="Mobile Recharge" />
          <NavLink to="/payments/airtime" icon={<Smartphone size={18} />} label="Manage Airtime" />
          <NavLink to="/payments/microfinance" icon={<Landmark size={18} />} label="Manage Microfinance" />
        </Group>

        <Group title="Manage Users" icon={<Users size={18} />} defaultOpen={defaultOpenUsers}>
          <NavLink to="/users/active" icon={<Users size={18} />} label="Active Users" />
          <NavLink to="/users/email-unverified" icon={<Users size={18} />} label="Email Unverified" />
          <NavLink to="/users/mobile-unverified" icon={<Users size={18} />} label="Mobile Unverified" />
          <NavLink to="/users/kyc-unverified" icon={<Users size={18} />} label="KYC Unverified" />
          <NavLink to="/users/kyc-pending" icon={<Users size={18} />} label="KYC Pending" />
          <NavLink to="/users/with-balance" icon={<Users size={18} />} label="With Balance" />
          <NavLink to="/users/banned" icon={<Users size={18} />} label="Banned Users" />
          <NavLink to="/users/deleted" icon={<Users size={18} />} label="Account Deleted" />
          <NavLink to="/users/all" icon={<Users size={18} />} label="All Users" />
          <NavLink to="/users/send-notification" icon={<Bell size={18} />} label="Send Notification" />
        </Group>

        <Group title="Utility Bills" icon={<ReceiptText size={18} />} defaultOpen={defaultOpenUtility}>
          <NavLink to="/utility/bills/pending" icon={<ReceiptText size={18} />} label="Pending" />
          <NavLink to="/utility/bills/approved" icon={<ReceiptText size={18} />} label="Approved" />
          <NavLink to="/utility/bills/rejected" icon={<ReceiptText size={18} />} label="Rejected" />
          <NavLink to="/utility/bills/all" icon={<ReceiptText size={18} />} label="All" />
          <NavLink to="/utility/companies" icon={<Building2 size={18} />} label="Manage Company" />
          <NavLink to="/utility/bill-categories" icon={<ReceiptText size={18} />} label="Bill Category" />
          <NavLink to="/utility/charge-settings" icon={<ReceiptText size={18} />} label="Charge Setting" />
        </Group>

        <NavLink to="/education-fee" icon={<Ticket size={20} />} label="Education Fee" />
        <NavLink to="/donations" icon={<HandCoins size={20} />} label="Manage Donation" />
        <NavLink to="/virtual-cards" icon={<CreditCard size={20} />} label="Manage Virtual Card" />
        <NavLink to="/request-money" icon={<HandCoins size={20} />} label="Request Money" />

        <Group title="Cards" icon={<CreditCard size={18} />} defaultOpen={defaultOpenCards}>
          <NavLink to="/cards/all" icon={<CreditCard size={18} />} label="ATM Cards" />
          <NavLink to="/cards/orders" icon={<CreditCard size={18} />} label="Card Orders" />
          <NavLink to="/cards/linked-bank-cards" icon={<Landmark size={18} />} label="Linked Bank Cards" />
          <NavLink to="/cards/nfc-payments" icon={<Radio size={18} />} label="NFC POS Payments" />
        </Group>

        <NavLink to="/children" icon={<Baby size={20} />} label="Child Accounts" />

        <Group title="Content" icon={<Bell size={18} />} defaultOpen={defaultOpenContent}>
          <NavLink to="/content/banners" icon={<Bell size={18} />} label="Banner Ads" />
          <NavLink to="/content/push" icon={<Bell size={18} />} label="Push Notification" />
        </Group>

        <Group title="Finance" icon={<Wallet size={18} />} defaultOpen={defaultOpenFinance}>
          <NavLink to="/finance/user-add-money" icon={<Wallet size={18} />} label="User Add Money" />
        </Group>

        <Group title="Business Banking" icon={<Building2 size={18} />} defaultOpen={location.pathname.startsWith('/business')}>
          <NavLink to="/business/all" icon={<Building2 size={18} />} label="All Businesses" />
          <NavLink to="/business/fraud-flags" icon={<ShieldCheck size={18} />} label="Fraud Flags" />
        </Group>

        <NavLink to="/settings" icon={<Settings size={20} />} label="Settings" />
      </div>

      <button
        className="nav-item"
        onClick={() => signOut(auth)}
        style={{ marginTop: 'auto', border: 'none', background: 'none', cursor: 'pointer', width: '100%' }}
      >
        <LogOut size={20} />
        Logout
      </button>
    </div>
  )
}
