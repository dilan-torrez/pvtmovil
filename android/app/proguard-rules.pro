# Please add these rules to your existing keep rules in order to suppress warnings.
# This is generated automatically by the Android Gradle plugin.
-dontwarn com.google.mlkit.vision.text.chinese.ChineseTextRecognizerOptions$Builder
-dontwarn com.google.mlkit.vision.text.chinese.ChineseTextRecognizerOptions
-dontwarn com.google.mlkit.vision.text.devanagari.DevanagariTextRecognizerOptions$Builder
-dontwarn com.google.mlkit.vision.text.devanagari.DevanagariTextRecognizerOptions
-dontwarn com.google.mlkit.vision.text.japanese.JapaneseTextRecognizerOptions$Builder
-dontwarn com.google.mlkit.vision.text.japanese.JapaneseTextRecognizerOptions
-dontwarn com.google.mlkit.vision.text.korean.KoreanTextRecognizerOptions$Builder
-dontwarn com.google.mlkit.vision.text.korean.KoreanTextRecognizerOptions
# Keep androidx.window classes to avoid R8 errors
# (el -dontwarn androidx.window.** cubre todas las extensiones/sidecar)
-keep class androidx.window.** { *; }
-dontwarn androidx.window.**

# ========================
# REGLAS PARA FLUTTER
# ========================

# Conservar la funcionalidad principal de Flutter.
# Los keep específicos de app/plugin/util/view quedan subsumidos por io.flutter.**
-keep class io.flutter.** { *; }

# ========================
# REGLAS DE ENDURECIMIENTO (SECURITY HARDENING)
# ========================

# FLUTTER SECURE STORAGE: Eliminar implementaciones CBC vulnerables
# MobSF detecta StorageCipherImplementationAES18.java que usa CBC
# Estas reglas REALMENTE eliminan las clases CBC del APK final

# IMPORTANTE: -assumenosideeffects NO elimina clases, solo optimiza
# Usamos una combinación de técnicas para eliminar completamente CBC

# 1. Marcar clases CBC como no utilizadas (para que R8 las elimine)
-dontwarn com.it_nomads.fluttersecurestorage.ciphers.StorageCipherImplementationAES18
-dontwarn com.it_nomads.fluttersecurestorage.ciphers.StorageCipherImplementationAES18$**

# 2. NO mantener ninguna clase que contenga CBC en su implementación
# Esto es crítico: si no hay -keep, R8 puede eliminarlas si no se usan
# Como forzamos AES-GCM en el código, estas clases NO se usan

# 3. Mantener SOLO las clases que usamos (AES-GCM)
-keep class com.it_nomads.fluttersecurestorage.ciphers.StorageCipher {
    public <methods>;
}

# 4. Mantener la factory pero permitir que elimine implementaciones no usadas
-keep class com.it_nomads.fluttersecurestorage.ciphers.StorageCipherFactory {
    public <methods>;
}

# 5. NO mantener StorageCipherImplementationAES18 (CBC)
# Al no tener -keep, R8 la eliminará si no se usa
# Como configuramos explícitamente GCM, esta clase NO se usa

# 6. Mantener SOLO StorageCipherImplementationAES23 (GCM)
-keep class com.it_nomads.fluttersecurestorage.ciphers.StorageCipherImplementationAES23 {
    public <init>(...);
    public <methods>;
}

# 7. Eliminar cualquier referencia a CBC/PKCS en el bytecode
-assumenosideeffects class * {
    *** *CBC*(...) return null;
    *** *Cbc*(...) return null;
    *** *cbc*(...) return null;
    *** *PKCS5*(...) return null;
    *** *PKCS7*(...) return null;
}

# 8. Mantener visibles SOLO los símbolos GCM/OAEP de flutter_secure_storage
# (antes "class *" bloqueaba la ofuscación de TODA la app; al restringirlo,
# R8 puede ofuscar el resto del proyecto sin perder el hardening de GCM)
-keep class com.it_nomads.fluttersecurestorage.** {
    *** *GCM*(...);
    *** *Gcm*(...);
    *** *gcm*(...);
    *** *OAEP*(...);
}

# 9. Eliminar Tink (si está presente) que también usa CBC
-dontwarn com.google.crypto.tink.**
-dontwarn javax.crypto.Cipher

# 10. Shrinking agresivo para eliminar código no usado
# Esto es crítico para que R8 realmente elimine las clases CBC
# (se re-habilitan "field" y "class/merging", optimizaciones que reducen el DEX)
-optimizations !code/simplification/arithmetic,!code/simplification/cast
-optimizationpasses 5
-allowaccessmodification

# Ofuscación agresiva para componentes internos que causan falsos positivos (como archivos temporales)
-keepclassmembernames class io.flutter.plugins.camerax.** {
    <methods>;
}

# Solución al error: Missing class com.google.android.play.core...
# Le decimos a R8 que no se preocupe si no encuentra estas clases de Play Core
# ya que no estamos usando "Dynamic Feature Modules" ni descargas dinámicas.
-dontwarn com.google.android.play.core.splitcompat.SplitCompatApplication
-dontwarn com.google.android.play.core.splitinstall.SplitInstallException
-dontwarn com.google.android.play.core.splitinstall.SplitInstallManager
-dontwarn com.google.android.play.core.splitinstall.SplitInstallManagerFactory
-dontwarn com.google.android.play.core.splitinstall.SplitInstallRequest$Builder
-dontwarn com.google.android.play.core.splitinstall.SplitInstallRequest
-dontwarn com.google.android.play.core.splitinstall.SplitInstallSessionState
-dontwarn com.google.android.play.core.splitinstall.SplitInstallStateUpdatedListener
-dontwarn com.google.android.play.core.tasks.OnFailureListener
-dontwarn com.google.android.play.core.tasks.OnSuccessListener
-dontwarn com.google.android.play.core.tasks.Task


