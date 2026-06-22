# Naver Login SDK — R8이 내부 Koin DI 서비스 로케이터 클래스를 제거/난독화하면
# NidServiceLocator.<clinit>에서 ClassCastException이 발생하므로 전체 보존
-keep class com.navercorp.nid.** { *; }
-keep interface com.navercorp.nid.** { *; }
-dontwarn com.navercorp.nid.**
