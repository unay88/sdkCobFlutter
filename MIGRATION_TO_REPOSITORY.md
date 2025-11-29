# Migration dari Path Lokal ke Repository

## Perubahan yang Dilakukan

### Sebelum (Path Lokal)
```ruby
# bjb_cob_sdk.podspec
s.dependency 'sdkCob', :path => '/Users/indrapermana/Code/SMB/test/ipCob01/Archive/sdkCob2'
```

### Sesudah (Repository - seperti Android Maven)
```ruby
# bjb_cob_sdk.podspec
s.dependency 'sdkCob', '1.0.0'
```

## Langkah-langkah Migration

### 1. Update sdkCob.podspec
- Ubah source dari `:path => "."` ke git repository
- Set homepage dan author yang benar

### 2. Update bjb_cob_sdk.podspec
- Ubah dependency dari path lokal ke version number
- Mirip dengan Android: `implementation 'com.bjb.cob:cob-lib:0.4.2'`

### 3. Update Podfile (jika perlu)
- Tambahkan source repository jika menggunakan private repository
- Hapus dependency path lokal

### 4. Publish sdkCob
```bash
cd /Users/indrapermana/Code/SMB/test/ipCob01/Archive/sdkCob2
./publish_to_cocoapods.sh
```

## Keuntungan

1. **Konsistensi**: iOS dan Android menggunakan repository dependency
2. **Versioning**: Mudah manage versi seperti Android Maven
3. **Distribution**: Tidak bergantung pada path lokal
4. **CI/CD**: Lebih mudah untuk automation

## Penggunaan

### Android
```gradle
implementation 'com.bjb.cob:cob-lib:0.4.2'
```

### iOS
```ruby
pod 'sdkCob', '1.0.0'
```

Sekarang kedua platform menggunakan repository dependency!