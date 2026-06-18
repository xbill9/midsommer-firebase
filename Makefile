# Midsommer Madness - Flutter Build and Development Automation Makefile
# Swedish-themed retro arcade game refactored to Flutter.

JAVA_HOME ?= /usr/lib/jvm/java-25-openjdk-amd64
export JAVA_HOME
export PATH := $(JAVA_HOME)/bin:$(PATH)
export ANDROID_HOME := /home/xbill/android-sdk

.PHONY: help dev run build-apk build-ios install-apk clean logcat deploy firebase-logs firebase-emulators deploy-preview firebase-status deploy-rules

# Default target: show help
help:
	@echo "========================================================================"
	@echo "🇸🇪  Midsommer Madness Flutter Build & Development Controls  🇸🇪"
	@echo "========================================================================"
	@echo "Available commands:"
	@echo "  make dev          - Start the local web server for browser play (from assets/)"
	@echo "  make build-apk    - Compile the Flutter App and build Debug APK"
	@echo "  make build-ios    - Compile the Flutter App and build iOS app (no codesign)"
	@echo "  make install-apk  - Install the compiled debug APK on a connected device/emulator"
	@echo "  make clean        - Clean Flutter build outputs and temporary caches"
	@echo "  make logcat       - Monitor application logs using Flutter logger"
	@echo "  make deploy       - Deploy the game to Firebase Hosting (manual bypass)"
	@echo "  make firebase-logs - Fetch the latest cloud logs from Google Cloud / Firebase"
	@echo "  make firebase-emulators - Start local Firebase Emulator Suite (Firestore & Hosting)"
	@echo "  make deploy-preview - Deploy a temporary preview channel to Firebase Hosting"
	@echo "  make firebase-status - Check current Firebase project configurations"
	@echo "  make deploy-rules - Deploy security rules for Cloud Firestore"
	@echo "  Note: Pushing/merging to 'master' on GitHub automatically triggers deployment."
	@echo "========================================================================"

# Development server
dev: run

run:
	npm run dev

# Build debug APK
build-apk:
	@echo "Building Flutter Debug APK..."
	flutter build apk --debug

# Build iOS App (without code signing)
build-ios:
	@echo "Building Flutter iOS App (without code signing)..."
	flutter build ios --no-codesign

# Install debug APK to device
install-apk:
	@echo "Installing Debug APK to connected device/emulator..."
	flutter install

# Clean the workspace
clean:
	@echo "Cleaning Flutter project build directories..."
	flutter clean
	@rm -rf build

# Logs monitoring for debugging
logcat:
	flutter logs

# Deploy web build to Firebase Hosting
deploy:
	@echo "Deploying to Firebase Hosting..."
	npx -y firebase-tools deploy --only hosting

# Fetch cloud logs from Google Cloud / Firebase
firebase-logs:
	@echo "Fetching latest Firebase/GCP cloud logs..."
	gcloud logging read --project=midsommer-madness --limit=20 --format="table(timestamp, severity, resource.type, textPayload, jsonPayload.message)"

# Start local Firebase Emulator Suite
firebase-emulators:
	@echo "Starting local Firebase emulators..."
	npx -y firebase-tools emulators:start

# Deploy to a temporary preview channel (expires in 7 days)
deploy-preview:
	@echo "Deploying temporary preview channel..."
	npx -y firebase-tools hosting:channel:deploy preview-$(shell date +%Y%m%d)

# Check active project configurations
firebase-status:
	@echo "Checking active Firebase project list..."
	npx -y firebase-tools projects:list

# Deploy security rules
deploy-rules:
	@echo "Deploying Firestore security rules..."
	npx -y firebase-tools deploy --only firestore:rules



