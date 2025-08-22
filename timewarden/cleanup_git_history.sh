#!/bin/bash

# Git History Cleanup Script for Firebase API Keys
# WARNING: This will rewrite git history - use with caution

echo "🚨 CRITICAL SECURITY CLEANUP 🚨"
echo "This script will remove exposed Firebase API keys from git history"
echo "Make sure you have:"
echo "1. ✅ Backed up your repository"
echo "2. ✅ Rotated Firebase API keys in Firebase Console"
echo "3. ✅ Notified team members about history rewrite"
echo ""

read -p "Do you want to proceed? (yes/no): " confirm
if [ "$confirm" != "yes" ]; then
    echo "Aborting cleanup"
    exit 1
fi

echo "Starting git history cleanup..."

# Remove firebase_options.dart from all commits
echo "Removing firebase_options.dart from git history..."
git filter-branch --force --index-filter \
'git rm --cached --ignore-unmatch lib/firebase_options.dart' \
--prune-empty --tag-name-filter cat -- --all

# Remove any references to the exposed API keys
echo "Removing API key references..."
git filter-branch --force --tree-filter \
'find . -name "*.dart" -type f -exec sed -i "" "s/AIzaSyD2ADJwltnYSlzq2v_j11MZroW7l6jPptw/[REDACTED_API_KEY]/g" {} \;' \
--prune-empty --tag-name-filter cat -- --all

git filter-branch --force --tree-filter \
'find . -name "*.dart" -type f -exec sed -i "" "s/AIzaSyCe5A1xrvD2ncq-9tV1w-QZIC95leNWsN8/[REDACTED_API_KEY]/g" {} \;' \
--prune-empty --tag-name-filter cat -- --all

# Clean up backup refs
echo "Cleaning up backup references..."
git for-each-ref --format='delete %(refname)' refs/original | git update-ref --stdin
git reflog expire --expire=now --all
git gc --prune=now --aggressive

echo "✅ Git history cleanup completed"
echo ""
echo "NEXT STEPS:"
echo "1. Force push to remote: git push origin --force --all"
echo "2. Force push tags: git push origin --force --tags"
echo "3. Ask team to re-clone repository"
echo "4. Monitor Firebase Console for any unauthorized access"
echo ""
echo "⚠️  WARNING: All team members must re-clone the repository!"
