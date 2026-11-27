#!/data/data/com.termux/files/usr/bin/bash
set -e

PROJECT="$PWD"
SDK="$HOME/Android/Sdk"
ANDROID_JAR="$SDK/platforms/android-35/android.jar"
BUILD="$PROJECT/build"
SRC="$PROJECT/app/src/main/java/com/tamim/novaai/MainActivity.java"
MANIFEST="$PROJECT/app/src/main/AndroidManifest.xml"

echo "===== 1. CHECKING FILES ====="
test -f "$ANDROID_JAR"
test -f "$SRC"
test -f "$MANIFEST"

rm -rf "$BUILD"
mkdir -p "$BUILD/classes" "$BUILD/dex"

echo "===== 2. CREATING APK ====="
aapt2 link \
  -o "$BUILD/unsigned.apk" \
  --manifest "$MANIFEST" \
  -I "$ANDROID_JAR" \
  --min-sdk-version 23 \
  --target-sdk-version 35 \
  --version-code 1 \
  --version-name 1.0

echo "===== 3. JAVA COMPILATION ====="
javac -source 8 -target 8 \
  -classpath "$ANDROID_JAR" \
  -d "$BUILD/classes" \
  "$SRC"

echo "===== 4. DEX GENERATION ====="
d8 --lib "$ANDROID_JAR" \
  --output "$BUILD/dex" \
  "$BUILD/classes/com/tamim/novaai/MainActivity.class"

echo "===== 5. PACKAGING ====="
cd "$BUILD/dex"
zip -q "$BUILD/unsigned.apk" classes.dex

echo "===== 6. ZIP ALIGN ====="
zipalign -f 4 "$BUILD/unsigned.apk" "$BUILD/aligned.apk"

echo "===== 7. SIGNING KEY ====="
KEY="$PROJECT/nova-release.jks"

if [ ! -f "$KEY" ]; then
  keytool -genkeypair -v \
    -keystore "$KEY" \
    -alias nova \
    -keyalg RSA \
    -keysize 2048 \
    -validity 10000 \
    -storepass novatest123 \
    -keypass novatest123 \
    -dname "CN=Nova AI, OU=App, O=Nova, L=Kushtia, ST=Khulna, C=BD"
fi

echo "===== 8. APK SIGNING ====="
apksigner sign \
  --ks "$KEY" \
  --ks-key-alias nova \
  --ks-pass pass:novatest123 \
  --key-pass pass:novatest123 \
  --out "$PROJECT/NovaAI.apk" \
  "$BUILD/aligned.apk"

echo "===== 9. VERIFY ====="
apksigner verify "$PROJECT/NovaAI.apk"

echo "===== BUILD SUCCESS ====="
ls -lh "$PROJECT/NovaAI.apk"
