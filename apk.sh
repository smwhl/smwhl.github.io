#!/bin/bash

# ============================================
# 1.SH - FINAL ANTI FAIL
# Semua file lengkap
# ============================================

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TOKEN_FILE="$SCRIPT_DIR/token.txt"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}🚀 1.SH - ANTI FAIL VERSION${NC}"
echo -e "${BLUE}========================================${NC}"

# ========== CEK TOKEN ==========
if [ -f "$TOKEN_FILE" ]; then
    TOKEN=$(cat "$TOKEN_FILE" 2>/dev/null | tr -d '\n\r')
    echo -e "${GREEN}✅ Token ditemukan!${NC}"
else
    echo -e "${RED}❌ token.txt tidak ditemukan!${NC}"
    exit 1
fi

if [ ${#TOKEN} -lt 10 ]; then
    echo -e "${RED}❌ Token tidak valid!${NC}"
    exit 1
fi

# ========== SETUP GIT ==========
echo -e "${YELLOW}⚙️  Setup Git...${NC}"
git config --global user.email "smwhl@users.noreply.github.com"
git config --global user.name "smwhl"
git config --global init.defaultBranch main

# ========== CLEAN ==========
rm -rf .git

# ========== INIT ==========
git init

# ========== REMOTE ==========
git remote add origin "https://x-access-token:${TOKEN}@github.com/smwhl/smwhl.github.io.git"

# ========== .gitignore ==========
cat > .gitignore << 'EOF'
# Security
token.txt
*.txt
*.log

# Android
*.apk
*.aab
.gradle/
build/
app/build/
local.properties
*.iml
.idea/
.DS_Store
EOF

# ========== CREATE ALL FILES ==========

# --- PROJECT BUILD.GRADLE ---
cat > build.gradle << 'EOF'
buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        classpath 'com.android.tools.build:gradle:8.1.0'
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}
EOF

# --- SETTINGS.GRADLE ---
cat > settings.gradle << 'EOF'
pluginManagement {
    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}
dependencyResolutionManagement {
    repositoriesMode.set(RepositoriesMode.FAIL_ON_PROJECT_REPOS)
    repositories {
        google()
        mavenCentral()
    }
}
rootProject.name = "BpexWebApp"
include ':app'
EOF

# --- GRADLE.PROPERTIES ---
cat > gradle.properties << 'EOF'
org.gradle.jvmargs=-Xmx2048m
android.useAndroidX=true
android.enableJetifier=true
EOF

# --- GRADLE WRAPPER ---
mkdir -p gradle/wrapper
cat > gradle/wrapper/gradle-wrapper.properties << 'EOF'
distributionBase=GRADLE_USER_HOME
distributionPath=wrapper/dists
distributionUrl=https\://services.gradle.org/distributions/gradle-8.2-bin.zip
zipStoreBase=GRADLE_USER_HOME
zipStorePath=wrapper/dists
EOF

curl -L -o gradle/wrapper/gradle-wrapper.jar \
  https://raw.githubusercontent.com/gradle/gradle/v8.2.0/gradle/wrapper/gradle-wrapper.jar 2>/dev/null

cat > gradlew << 'EOF'
#!/bin/sh
exec gradle "$@"
EOF
chmod +x gradlew

# --- APP/GRADLE ---
mkdir -p app
cat > app/build.gradle << 'EOF'
plugins {
    id 'com.android.application'
}

android {
    namespace 'com.bpex.webapp'
    compileSdk 34

    defaultConfig {
        applicationId "com.bpex.webapp"
        minSdk 21
        targetSdk 34
        versionCode 1
        versionName "1.0"
    }

    buildTypes {
        debug {
            minifyEnabled false
            debuggable true
        }
        release {
            minifyEnabled true
            proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
        }
    }

    compileOptions {
        sourceCompatibility JavaVersion.VERSION_17
        targetCompatibility JavaVersion.VERSION_17
    }
}

dependencies {
    implementation 'androidx.appcompat:appcompat:1.6.1'
    implementation 'androidx.webkit:webkit:1.9.0'
    implementation 'androidx.swiperefreshlayout:swiperefreshlayout:1.1.0'
}
EOF

# --- ANDROIDMANIFEST ---
mkdir -p app/src/main
cat > app/src/main/AndroidManifest.xml << 'EOF'
<?xml version="1.0" encoding="utf-8"?>
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    package="com.bpex.webapp">

    <uses-permission android:name="android.permission.INTERNET" />
    <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
    <uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
    <uses-permission android:name="android.permission.CAMERA" />
    <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
    <uses-permission android:name="android.permission.VIBRATE" />

    <application
        android:allowBackup="true"
        android:icon="@mipmap/ic_launcher"
        android:label="@string/app_name"
        android:roundIcon="@mipmap/ic_launcher_round"
        android:supportsRtl="true"
        android:theme="@style/Theme.AppCompat.NoActionBar"
        android:usesCleartextTraffic="true">

        <activity
            android:name=".MainActivity"
            android:exported="true">
            <intent-filter>
                <action android:name="android.intent.action.MAIN" />
                <category android:name="android.intent.category.LAUNCHER" />
            </intent-filter>
        </activity>

        <provider
            android:name="androidx.core.content.FileProvider"
            android:authorities="${applicationId}.fileprovider"
            android:exported="false"
            android:grantUriPermissions="true">
            <meta-data
                android:name="android.support.FILE_PROVIDER_PATHS"
                android:resource="@xml/file_paths" />
        </provider>

    </application>
</manifest>
EOF

# --- MAINACTIVITY.JAVA ---
mkdir -p app/src/main/java/com/bpex/webapp
cat > app/src/main/java/com/bpex/webapp/MainActivity.java << 'EOF'
package com.bpex.webapp;

import android.app.DownloadManager;
import android.content.Context;
import android.net.Uri;
import android.os.Build;
import android.os.Bundle;
import android.os.Environment;
import android.webkit.CookieManager;
import android.webkit.DownloadListener;
import android.webkit.WebChromeClient;
import android.webkit.WebSettings;
import android.webkit.WebView;
import android.webkit.WebViewClient;
import android.widget.ProgressBar;
import android.widget.Toast;
import androidx.appcompat.app.AppCompatActivity;
import androidx.swiperefreshlayout.widget.SwipeRefreshLayout;

public class MainActivity extends AppCompatActivity {
    private WebView webView;
    private ProgressBar progressBar;
    private SwipeRefreshLayout swipeRefreshLayout;
    private String url = "https://smwhl.github.io";

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);

        webView = findViewById(R.id.webView);
        progressBar = findViewById(R.id.progressBar);
        swipeRefreshLayout = findViewById(R.id.swipeRefreshLayout);

        setupWebView();
        setupSwipeRefresh();
        webView.loadUrl(url);
    }

    private void setupWebView() {
        WebSettings webSettings = webView.getSettings();
        webSettings.setJavaScriptEnabled(true);
        webSettings.setDomStorageEnabled(true);
        webSettings.setUseWideViewPort(true);
        webSettings.setBuiltInZoomControls(true);
        webSettings.setDisplayZoomControls(false);
        webSettings.setDatabaseEnabled(true);
        webSettings.setAppCacheEnabled(true);
        webSettings.setCacheMode(WebSettings.LOAD_DEFAULT);

        CookieManager.getInstance().setAcceptCookie(true);
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
            webSettings.setMixedContentMode(WebSettings.MIXED_CONTENT_ALWAYS_ALLOW);
        }

        webView.setWebViewClient(new WebViewClient() {
            @Override
            public void onPageFinished(WebView view, String url) {
                progressBar.setVisibility(android.view.View.GONE);
                swipeRefreshLayout.setRefreshing(false);
            }
        });

        webView.setWebChromeClient(new WebChromeClient() {
            @Override
            public void onProgressChanged(WebView view, int newProgress) {
                if (newProgress < 100) {
                    progressBar.setVisibility(android.view.View.VISIBLE);
                    progressBar.setProgress(newProgress);
                } else {
                    progressBar.setVisibility(android.view.View.GONE);
                }
            }
        });

        webView.setDownloadListener((url, userAgent, contentDisposition, mimetype, contentLength) -> {
            DownloadManager.Request request = new DownloadManager.Request(Uri.parse(url));
            request.setAllowedNetworkTypes(DownloadManager.Request.NETWORK_WIFI | DownloadManager.Request.NETWORK_MOBILE);
            request.setTitle("Downloading...");
            request.setNotificationVisibility(DownloadManager.Request.VISIBILITY_VISIBLE_NOTIFY_COMPLETED);
            request.setDestinationInExternalPublicDir(Environment.DIRECTORY_DOWNLOADS, "download_" + System.currentTimeMillis());
            DownloadManager manager = (DownloadManager) getSystemService(Context.DOWNLOAD_SERVICE);
            if (manager != null) {
                manager.enqueue(request);
                Toast.makeText(MainActivity.this, "Download started", Toast.LENGTH_SHORT).show();
            }
        });
    }

    private void setupSwipeRefresh() {
        swipeRefreshLayout.setOnRefreshListener(() -> {
            webView.reload();
            Toast.makeText(this, "Refreshing...", Toast.LENGTH_SHORT).show();
        });
        swipeRefreshLayout.setColorSchemeColors(android.R.color.holo_blue_bright);
    }

    @Override
    public void onBackPressed() {
        if (webView.canGoBack()) {
            webView.goBack();
        } else {
            super.onBackPressed();
        }
    }
}
EOF

# --- LAYOUT ---
mkdir -p app/src/main/res/layout
cat > app/src/main/res/layout/activity_main.xml << 'EOF'
<?xml version="1.0" encoding="utf-8"?>
<LinearLayout xmlns:android="http://schemas.android.com/apk/res/android"
    xmlns:app="http://schemas.android.com/apk/res-auto"
    android:layout_width="match_parent"
    android:layout_height="match_parent"
    android:orientation="vertical">
    <androidx.swiperefreshlayout.widget.SwipeRefreshLayout
        android:id="@+id/swipeRefreshLayout"
        android:layout_width="match_parent"
        android:layout_height="match_parent">
        <RelativeLayout
            android:layout_width="match_parent"
            android:layout_height="match_parent">
            <WebView
                android:id="@+id/webView"
                android:layout_width="match_parent"
                android:layout_height="match_parent" />
            <ProgressBar
                android:id="@+id/progressBar"
                style="?android:attr/progressBarStyleHorizontal"
                android:layout_width="match_parent"
                android:layout_height="3dp"
                android:layout_alignParentTop="true"
                android:max="100"
                android:visibility="gone"
                app:progressTint="@color/colorPrimary" />
        </RelativeLayout>
    </androidx.swiperefreshlayout.widget.SwipeRefreshLayout>
</LinearLayout>
EOF

# --- RESOURCES ---
mkdir -p app/src/main/res/values
cat > app/src/main/res/values/strings.xml << 'EOF'
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <string name="app_name">BpexWebApp</string>
</resources>
EOF

cat > app/src/main/res/values/colors.xml << 'EOF'
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <color name="colorPrimary">#2196F3</color>
    <color name="colorPrimaryDark">#1976D2</color>
    <color name="colorAccent">#FF4081</color>
</resources>
EOF

cat > app/src/main/res/values/styles.xml << 'EOF'
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <style name="Theme.AppCompat.NoActionBar" parent="Theme.AppCompat.Light.NoActionBar" />
</resources>
EOF

mkdir -p app/src/main/res/xml
cat > app/src/main/res/xml/file_paths.xml << 'EOF'
<?xml version="1.0" encoding="utf-8"?>
<paths>
    <external-path name="external" path="." />
    <external-files-path name="external_files" path="." />
    <cache-path name="cache" path="." />
</paths>
EOF

# --- ICON (dummy) ---
mkdir -p app/src/main/res/drawable
touch app/src/main/res/drawable/splash_logo.png

# --- WORKFLOW ---
mkdir -p .github/workflows
cat > .github/workflows/build.yml << 'EOF'
name: Android Build APK

on:
  push:
    branches: [ main ]

jobs:
  build:
    runs-on: ubuntu-latest
    env:
      FORCE_JAVASCRIPT_ACTIONS_TO_NODE24: true
    
    steps:
      - uses: actions/checkout@v4
      
      - name: Setup JDK
        uses: actions/setup-java@v4
        with:
          java-version: '17'
          distribution: 'temurin'
          
      - name: Setup Android SDK
        uses: android-actions/setup-android@v3
        
      - name: Build APK
        run: |
          cd app
          gradle assembleDebug
          
      - name: Upload APK
        uses: actions/upload-artifact@v4
        with:
          name: app-debug
          path: app/build/outputs/apk/debug/*.apk
          overwrite: true
EOF

# ========== GIT ADD & COMMIT ==========
echo -e "${GREEN}📤 Add semua file...${NC}"
git add .

echo -e "${GREEN}📝 Commit...${NC}"
git commit -m "Deploy: $(date '+%Y-%m-%d %H:%M:%S')"

echo -e "${GREEN}🚀 Push ke GitHub...${NC}"
git push -u origin main --force 2>&1 | grep -v "token"

if [ ${PIPESTATUS[0]} -eq 0 ]; then
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}✅ DEPLOY BERHASIL!${NC}"
    echo -e "${GREEN}🌐 https://smwhl.github.io${NC}"
    echo -e "${GREEN}📦 https://github.com/smwhl/smwhl.github.io/actions${NC}"
    echo -e "${GREEN}========================================${NC}"
else
    echo -e "${RED}❌ DEPLOY GAGAL!${NC}"
    exit 1
fi

unset TOKEN
