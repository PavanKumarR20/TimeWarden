#!/bin/bash

# TimeWarden Firestore Rules Deployment Script

echo "🔥 TimeWarden Firestore Rules Deployment"
echo "======================================="

# Check if Firebase CLI is installed and working
echo "Checking Firebase CLI..."
if ! command -v firebase &> /dev/null; then
    echo "❌ Firebase CLI not found. Please install it first:"
    echo "npm install -g firebase-tools"
    exit 1
fi

# Check Node.js version
NODE_VERSION=$(node --version | cut -d'v' -f2 | cut -d'.' -f1)
if [ "$NODE_VERSION" -lt 20 ]; then
    echo "❌ Node.js version $NODE_VERSION detected. Please upgrade to Node.js 20+ or 22+"
    echo "Visit: https://nodejs.org/"
    exit 1
fi

echo "✅ Firebase CLI found"

# Login check
echo "Checking Firebase authentication..."
if ! firebase projects:list &> /dev/null; then
    echo "🔐 Please login to Firebase:"
    firebase login
fi

echo "✅ Firebase authentication successful"

# Deploy Firestore rules
echo "📜 Deploying Firestore security rules..."
firebase deploy --only firestore:rules --project timewarden-b426f

if [ $? -eq 0 ]; then
    echo ""
    echo "🎉 SUCCESS! Firestore rules deployed successfully!"
    echo ""
    echo "Your TimeWarden app should now be able to:"
    echo "✅ Add new habits"
    echo "✅ Update existing habits"
    echo "✅ Track habit completions"
    echo "✅ Access user-specific data securely"
    echo ""
    echo "Try adding a habit again in your app!"
else
    echo ""
    echo "❌ FAILED to deploy Firestore rules"
    echo "Please check the error messages above"
    exit 1
fi
