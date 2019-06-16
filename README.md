# QLDataHandler

## Presentation

This framework is in beta.
Its goal is to facilitate the utilisation of Firebase and Algolia using reactive programming with RxSwift.

## How to install

You can add source files directly in your project or use cocapods, see below:

```
pod init
```

In podfile, insert:
```
platform :ios, '12.0'

source "https://gitlab.com/qLiardeaux/Specs.git" # Repository to get QLCalendar

target 'NameOfYourProject' do
   use_frameworks!

    pod 'QLDataHandler'

end
```

```
pod install
```
## Dependencies

```
Firebase/Core
Firebase/Database
Firebase/Auth
Firebase/Firestore
Firebase/Storage
RxSwift
RxCocoa
Geofirestore
InstantSearchClient
```
## Licence

MIT

