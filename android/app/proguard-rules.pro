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
-dontwarn androidx.window.extensions.WindowExtensions
-dontwarn androidx.window.extensions.WindowExtensionsProvider
-dontwarn androidx.window.extensions.area.ExtensionWindowAreaPresentation
-dontwarn androidx.window.extensions.area.ExtensionWindowAreaStatus
-dontwarn androidx.window.extensions.area.WindowAreaComponent
-dontwarn androidx.window.extensions.layout.DisplayFeature
-dontwarn androidx.window.extensions.layout.FoldingFeature
-dontwarn androidx.window.extensions.layout.WindowLayoutComponent
-dontwarn androidx.window.extensions.layout.WindowLayoutInfo
-dontwarn androidx.window.extensions.embedding.ActivityStack
-dontwarn androidx.window.extensions.embedding.ActivityEmbeddingComponent
-dontwarn androidx.window.extensions.embedding.ActivityRule
-dontwarn androidx.window.extensions.embedding.ActivityRule$Builder
-dontwarn androidx.window.extensions.embedding.EmbeddingRule
-dontwarn androidx.window.extensions.embedding.SplitAttributes
-dontwarn androidx.window.extensions.embedding.SplitAttributes$Builder
-dontwarn androidx.window.extensions.embedding.SplitAttributes$SplitType
-dontwarn androidx.window.extensions.embedding.SplitAttributes$SplitType$ExpandContainersSplitType
-dontwarn androidx.window.extensions.embedding.SplitAttributes$SplitType$HingeSplitType
-dontwarn androidx.window.extensions.embedding.SplitAttributes$SplitType$RatioSplitType
-dontwarn androidx.window.extensions.embedding.SplitAttributesCalculatorParams
-dontwarn androidx.window.extensions.embedding.SplitInfo
-dontwarn androidx.window.extensions.embedding.SplitPairRule
-dontwarn androidx.window.extensions.embedding.SplitPairRule$Builder
-dontwarn androidx.window.extensions.embedding.SplitPlaceholderRule
-dontwarn androidx.window.extensions.embedding.SplitPlaceholderRule$Builder
-dontwarn androidx.window.sidecar.SidecarDeviceState
-dontwarn androidx.window.sidecar.SidecarDisplayFeature
-dontwarn androidx.window.sidecar.SidecarInterface$SidecarCallback
-dontwarn androidx.window.sidecar.SidecarInterface
-dontwarn androidx.window.sidecar.SidecarProvider
-dontwarn androidx.window.sidecar.SidecarWindowLayoutInfo

# Keep androidx.window classes to avoid R8 errors
-keep class androidx.window.** { *; }
-keep interface androidx.window.** { *; }
-dontwarn androidx.window.**

# ========================
# REGLAS PARA FLUTTER
# ========================

# Conservar la funcionalidad principal de Flutter
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# ========================
# REGLAS DE ENDURECIMIENTO (SECURITY HARDENING)
# ========================

# Eliminar algoritmos de cifrado no seguros (AES-CBC) que MobSF reporta
# Estas reglas eliminan clases de cifrado CBC que son vulnerables a padding oracle attacks
-dontwarn com.google.crypto.tink.**
-dontwarn javax.crypto.Cipher

# Eliminar implementaciones de AES-CBC de diferentes librerías
-assumenosideeffects class com.google.crypto.tink.subtle.AesCbc* {
    public *;
}

# Eliminar cualquier método que contenga CBC en su nombre
-assumenosideeffects class * {
    *** *CBC*(...);
    *** *Cbc*(...);
    *** *cbc*(...);
}

# Mantener solo implementaciones seguras (GCM)
-keep class * {
    *** *GCM*(...);
    *** *Gcm*(...);
    *** *gcm*(...);
}

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


