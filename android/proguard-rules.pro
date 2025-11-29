-keep class com.squareup.okhttp3.** { *; }
-keep class okhttp3.** { *; }
-keep class okio.** { *; }
-keep class retrofit2.** { *; }
-keep class com.squareup.moshi.** { *; }
-dontwarn okio.**
-dontwarn javax.annotation.**
-dontwarn org.codehaus.mojo.animal_sniffer.*

# Public API
-keep class com.bjb.cob.** { public *; }

# Jika ada GTF AAR, pertahankan kelas public-nya (sesuaikan package):
# -keep class com.gtf.onekyc.** { *; }