import { auth } from '../firebase/client'

const baseUrl = import.meta.env.VITE_API_URL || 'http://localhost:3000/api'

export async function apiRequest(endpoint, options = {}) {
  const currentUser = auth?.currentUser
  const token = currentUser ? await currentUser.getIdToken() : ''
  
  const headers = {
    'Content-Type': 'application/json',
    ...(token ? { 'Authorization': `Bearer ${token}` } : {}),
    ...options.headers,
  }

  const response = await fetch(`${baseUrl}${endpoint}`, {
    ...options,
    headers,
  })

  if (!response.ok) {
    const errorData = await response.json().catch(() => ({}))
    throw new Error(errorData.error || `Request failed with status ${response.status}`)
  }

  return response.json()
}
