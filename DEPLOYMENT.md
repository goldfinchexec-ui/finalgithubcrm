# 🚀 Firebase Hosting Deployment Guide

## ✅ Setup Complete!

Your Goldfinch CRM is now ready for Firebase Hosting deployment with GitHub Actions.

## 📋 What's Been Configured

### Files Created/Updated:
- ✅ `firebase.json` - Firebase Hosting configuration with caching & security headers
- ✅ `firestore.rules` - Production-ready security rules (auth required)
- ✅ `.firebaserc` - Firebase project configuration
- ✅ `.github/workflows/firebase-hosting.yml` - GitHub Actions CI/CD pipeline

## 🔐 GitHub Setup (One-Time)

### Step 1: Create Firebase Service Account

Run this command in your terminal (requires Firebase CLI):

```bash
firebase init hosting:github
```

This will:
1. Link your GitHub repository
2. Create a service account
3. Add `FIREBASE_SERVICE_ACCOUNT_GOLDFINCHE_ED986` secret to your GitHub repo

**OR manually:**

1. Go to [Firebase Console](https://console.firebase.google.com/project/goldfinche-ed986/settings/serviceaccounts/adminsdk)
2. Click "Generate new private key"
3. Copy the JSON content
4. Go to your GitHub repo → Settings → Secrets and variables → Actions
5. Create new secret: `FIREBASE_SERVICE_ACCOUNT_GOLDFINCHE_ED986`
6. Paste the JSON content

### Step 2: Push to GitHub

```bash
git add .
git commit -m "Add Firebase Hosting configuration"
git push origin main
```

The GitHub Action will automatically:
- Build your Flutter web app
- Deploy to Firebase Hosting
- Your app will be live at: `https://goldfinche-ed986.web.app`

## 🎯 Manual Deployment (Optional)

If you want to deploy manually from your local machine:

```bash
# Build the web app
flutter build web --release

# Deploy to Firebase
firebase deploy --only hosting

# Deploy Firestore rules
firebase deploy --only firestore:rules
```

## 🔒 Security Rules Summary

Your Firestore is now protected with production-ready rules:

- ✅ Only authenticated users can access data
- ✅ Users can only modify their own user document
- ✅ All staff can read/write drivers, clients, transactions, bookings
- ✅ No public read/write access

## 📊 Firebase Hosting Features Enabled

1. **Single Page App Routing** - All routes redirect to index.html (works with go_router)
2. **Aggressive Caching** - Static assets cached for 1 year (31536000 seconds)
3. **Security Headers**:
   - X-Content-Type-Options: nosniff
   - X-Frame-Options: DENY
   - X-XSS-Protection: 1; mode=block

## 🌐 Your Live URLs

After deployment:

- **Production**: https://goldfinche-ed986.web.app
- **Alternative**: https://goldfinche-ed986.firebaseapp.com

## 🔄 Continuous Deployment

Every time you push to the `main` branch:
1. GitHub Actions runs automatically
2. Builds Flutter web (release mode)
3. Deploys to Firebase Hosting
4. Your changes are live in ~2-5 minutes

## 📱 Testing

Before pushing to production, test locally:

```bash
# Build and preview
flutter build web --release
firebase serve --only hosting

# Open browser to http://localhost:5000
```

## ⚠️ Important Notes

1. **Firebase Plan**: You're on the Free (Spark) plan
   - 10GB hosting storage
   - 360MB/day bandwidth
   - Upgrade to Blaze if you exceed limits

2. **First Load**: Flutter web apps are ~2-5MB
   - Subsequent visits are cached
   - Users will see the app load in ~1-3 seconds on good connections

3. **Custom Domain** (Optional):
   - Go to Firebase Console → Hosting → Add custom domain
   - Follow the DNS setup instructions

## 🐛 Troubleshooting

**GitHub Action fails?**
- Check if `FIREBASE_SERVICE_ACCOUNT_GOLDFINCHE_ED986` secret exists
- Verify the service account has "Firebase Hosting Admin" role

**App not updating?**
- Clear browser cache (Ctrl+Shift+R or Cmd+Shift+R)
- Check Firebase Console → Hosting for deployment status

**Auth not working on live site?**
- Verify your domain is authorized in Firebase Console → Authentication → Settings → Authorized domains

## ✨ Next Steps

1. Push your code to GitHub
2. Wait for GitHub Actions to complete
3. Visit https://goldfinche-ed986.web.app
4. Log in and verify everything works!

---

**Need help?** Check the GitHub Actions logs or Firebase Console for detailed deployment info.
