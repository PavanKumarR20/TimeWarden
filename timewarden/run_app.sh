#!/bin/bash

# TimeWarden App Runner
# Quick script to run the app with secure Firebase configuration

echo "🚀 Starting TimeWarden with secure Firebase config..."

flutter run \
  --dart-define=FIREBASE_WEB_API_KEY=AIzaSyCTcMgkx3eeRE7hMYb48Fc2P1nxyP8wwEw \
  --dart-define=FIREBASE_ANDROID_API_KEY=AIzaSyDzijUURC_aSkmw-1nFEeuKwTbT8cBk5yw \
  --dart-define=FIREBASE_IOS_API_KEY=AIzaSyBuv91ADrEz91ju0fqNwg8FqQDqYeH5VXI \
  --dart-define=FIREBASE_PROJECT_ID=timewarden-b426f \
  --dart-define=FIREBASE_MESSAGING_SENDER_ID=637467704431 \
  --dart-define=FIREBASE_STORAGE_BUCKET=timewarden-b426f.appspot.com \
  --dart-define=FIREBASE_AUTH_DOMAIN=timewarden-b426f.firebaseapp.com \
  --dart-define=FIREBASE_ANDROID_APP_ID=1:637467704431:android:51fd6dc24bcbd855773ca
