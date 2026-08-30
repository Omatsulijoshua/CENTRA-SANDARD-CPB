# central_stadard_cpb

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.









I have completed the migration of your banking app from Firebase to a custom Node.js backend and completely overhauled the UI to give it a premium, modern feel.

Summary of Improvements:
Custom Node.js Backend: I created a full-featured backend in the backend/ directory using Express and SQLite. It handles JWT authentication, KYC status, transaction history, and internal/external account resolution.
Account Confirmation: Integrated a "Resolve Account" feature. When you type a 10-digit account number in the "Send Money" or "Transfer" screens, the app automatically verifies the account name from the backend (mocking the Nigerian Bank/CBN API logic).
Beautiful UI:
Home & Cards: Redesigned with glassmorphism, gradients, and clean shadows.
Send Money: Added a stunning "Receiver Card" that appears once an account is resolved.
Success Flow: Integrated Lottie animations for a "wow" factor upon successful transfers.
Full Integration: The Flutter app is now fully linked to the Node.js API via a new ApiService. I've removed all Firebase dependencies and code.
Demo Login Details:
Email: demo@bank.com
Password: password123
Starting Balance: ₦500,000.00
Account Number: 0123456789
To Run the Backend:
Open your terminal in the backend folder.
Run node server.js.
Your server will start on port 3000.
Please check the Walkthrough and Task List artifacts for more details on the implementation!