# DineFlow

DineFlow is a Flutter-based restaurant management system designed to streamline operations across the dining experience. It supports multiple user roles such as admin, waiter, cashier, kitchen staff, and customers, bringing the whole restaurant workflow into a single digital platform.

## What this system does

- Admin dashboard for menu, tables, inventory, and staff operations
- Waiter workflow for taking orders and tracking status
- Kitchen order monitoring for preparing food efficiently
- Cashier flow for completion and settlement
- Customer self-service flow for table selection, ordering, and tracking
- Inventory monitoring with low-stock alerts
- Firebase-powered real-time data syncing

## How it works

The app is built with Flutter for the frontend and Firebase Firestore for the backend data layer. Riverpod is used for state management, and GoRouter handles screen navigation and role-based routing.

The typical flow is:

1. A user signs in based on role.
2. The router redirects them to the correct dashboard or screen.
3. Data is loaded from Firestore collections such as menu items, tables, orders, and inventory.
4. Providers update the UI in real time as changes happen.
5. Staff and customers can interact without needing separate systems.

## Features overview

- Customer table selection
- Menu browsing and cart management
- Order tracking
- Restaurant staff dashboards
- Inventory stock adjustment tracking
- Real-time low stock alerts
- Modular architecture for future expansion

## Setup instructions

### 1) Install Flutter

Make sure Flutter is installed and configured on your computer:

- https://flutter.dev/docs/get-started/install

### 2) Install dependencies

Open the project folder and run:

```bash
flutter pub get
```

### 3) Firebase setup

This project already includes Firebase configuration files, but you may need to connect it to your own Firebase project:

```bash
flutterfire configure
```

If you are using the existing Firebase setup in the project, make sure your Firebase project is active and has the required Firestore rules enabled.

### 4) Run the app

```bash
flutter run
```

## GitHub push instructions

To push this project to GitHub:

```bash
git init
git add .
git commit -m "Initial commit"
git branch -M main
git remote add origin https://github.com/adriancirz/Dineflow.git
git push -u origin main
```

If your repository already exists and you are connected to it, use:

```bash
git add .
git commit -m "Update project"
git push origin main
```

## Social media caption

DineFlow is a smart restaurant management system built to make service faster, smoother, and more organized. From order tracking to inventory control, it brings the whole dining experience into one connected app.

#Flutter #Firebase #RestaurantTech #AppDevelopment #DineFlow #StartupProject #MobileApp #BusinessSoftware

## Quick summary

DineFlow is a complete restaurant operations app that helps staff and customers stay connected in real time. It is built with Flutter and Firebase to make service, inventory, and order workflows more efficient.
