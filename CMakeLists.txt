cmake_minimum_required(VERSION 3.21)
project(DecenzaPocket VERSION 1.0.1 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

set(VERSION_CODE_FILE "${CMAKE_SOURCE_DIR}/versioncode.txt")
set(VERSION_HEADER "${CMAKE_BINARY_DIR}/version.h")

file(READ "${VERSION_CODE_FILE}" CURRENT_VERSION_CODE)
string(STRIP "${CURRENT_VERSION_CODE}" CURRENT_VERSION_CODE)
set(DECENZA_BUILD_NUMBER "${CURRENT_VERSION_CODE}" CACHE STRING
    "CFBundleVersion used by generated Apple platform targets")

configure_file(
    "${CMAKE_SOURCE_DIR}/src/version.h.in"
    "${VERSION_HEADER}"
    @ONLY
)

find_package(Qt6 6.8 REQUIRED COMPONENTS
    Core Gui Qml Quick QuickControls2 Network WebSockets Multimedia Svg
)

qt_standard_project_setup(REQUIRES 6.8)

set(SOURCES
    src/main.cpp
    src/core/settings.h
    src/core/settings.cpp
    src/network/discovery.h
    src/network/discovery.cpp
    src/network/decenzaclient.h
    src/network/decenzaclient.cpp
    src/core/notificationmanager.h
    src/core/notificationmanager.cpp
    src/network/relayclient.h
    src/network/relayclient.cpp
    src/network/connectionmanager.h
    src/network/connectionmanager.cpp
    src/network/remotecontrolclient.h
    src/network/remotecontrolclient.cpp
    src/core/nativebridge.h
)

if(ANDROID)
    list(APPEND SOURCES src/core/nativebridge_android.cpp)
elseif(IOS)
    list(APPEND SOURCES src/core/nativebridge_ios.mm)
else()
    list(APPEND SOURCES src/core/nativebridge_stub.cpp)
endif()

qt_add_executable(DecenzaPocket ${SOURCES})

# Resources
qt_add_resources(DecenzaPocket "sounds"
    PREFIX "/"
    FILES
        resources/sounds/speech.wav
)

qt_add_resources(DecenzaPocket "icons"
    PREFIX "/"
    FILES
        resources/icons/back.svg
        resources/icons/settings.svg
)

qt_add_resources(DecenzaPocket "qml"
    PREFIX "/qml"
    BASE "qml"
    FILES
        qml/qmldir
        qml/Main.qml
        qml/Theme.qml
        qml/StatusCard.qml
        qml/PowerButton.qml
        qml/ConnectionIndicator.qml
        qml/PairingPage.qml
        qml/SettingsPage.qml
        qml/BottomBar.qml
        qml/RemoteControlPage.qml
)

target_include_directories(DecenzaPocket PRIVATE
    ${CMAKE_BINARY_DIR}
    ${CMAKE_SOURCE_DIR}/src
)

target_link_libraries(DecenzaPocket PRIVATE
    Qt6::Core Qt6::Gui Qt6::Qml Qt6::Quick Qt6::QuickControls2
    Qt6::Network Qt6::WebSockets Qt6::Multimedia Qt6::Svg
)

set_target_properties(DecenzaPocket PROPERTIES
    MACOSX_BUNDLE TRUE
    WIN32_EXECUTABLE TRUE
    QT_ANDROID_PACKAGE_SOURCE_DIR "${CMAKE_SOURCE_DIR}/android"
)

if(ANDROID)
    # OpenSSL for TLS (required for wss:// WebSocket relay)
    include(FetchContent)
    FetchContent_Declare(
        android_openssl
        DOWNLOAD_EXTRACT_TIMESTAMP true
        URL https://github.com/KDAB/android_openssl/archive/refs/heads/master.zip
    )
    FetchContent_MakeAvailable(android_openssl)
    include(${android_openssl_SOURCE_DIR}/android_openssl.cmake)
    add_android_openssl_libraries(DecenzaPocket)

    set(ANDROID_VERSION_NAME "${CMAKE_PROJECT_VERSION}")
    set(ANDROID_VERSION_CODE "${CURRENT_VERSION_CODE}")
    configure_file(
        "${CMAKE_SOURCE_DIR}/android/AndroidManifest.xml.in"
        "${CMAKE_SOURCE_DIR}/android/AndroidManifest.xml"
        @ONLY
    )
endif()

if(IOS)
    set(DECENZA_MAIN_PROFILE_SPECIFIER "" CACHE STRING
        "Optional manual-signing profile name for the main iOS app")
    set(DECENZA_WIDGET_PROFILE_SPECIFIER "" CACHE STRING
        "Optional manual-signing profile name for the widget extension")

    # Keep the widget in the same generated Xcode project as the main app.
    # This lets both GitHub Actions and Xcode Cloud archive one complete
    # product without a post-archive copy/signing step.
    enable_language(Swift)

    add_executable(PowerWidgetExtension MACOSX_BUNDLE
        ios/PowerWidget/PowerWidget.swift
        ios/PowerWidget/PowerWidgetBundle.swift
        ios/PowerWidget/SharedState.swift
        ios/PowerWidget/WebSocketCommand.swift
        ios/PowerWidget/Assets.xcassets
    )

    set_source_files_properties(
        "${CMAKE_CURRENT_SOURCE_DIR}/ios/PowerWidget/Assets.xcassets"
        PROPERTIES MACOSX_PACKAGE_LOCATION Resources
    )

    set_target_properties(PowerWidgetExtension PROPERTIES
        BUNDLE_EXTENSION "appex"
        MACOSX_BUNDLE_GUI_IDENTIFIER "com.janhagenclausen.DecenzaPocket.PowerWidget"
        MACOSX_BUNDLE_BUNDLE_VERSION "${DECENZA_BUILD_NUMBER}"
        MACOSX_BUNDLE_SHORT_VERSION_STRING "${CMAKE_PROJECT_VERSION}"
        MACOSX_BUNDLE_INFO_PLIST "${CMAKE_CURRENT_SOURCE_DIR}/ios/PowerWidget/Info.plist"
        XCODE_PRODUCT_TYPE "com.apple.product-type.app-extension"
        XCODE_ATTRIBUTE_APPLICATION_EXTENSION_API_ONLY "YES"
        XCODE_ATTRIBUTE_CODE_SIGN_ENTITLEMENTS "${CMAKE_CURRENT_SOURCE_DIR}/ios/PowerWidget/PowerWidgetExtension.entitlements"
        XCODE_ATTRIBUTE_CURRENT_PROJECT_VERSION "${DECENZA_BUILD_NUMBER}"
        XCODE_ATTRIBUTE_GENERATE_INFOPLIST_FILE "NO"
        XCODE_ATTRIBUTE_MARKETING_VERSION "${CMAKE_PROJECT_VERSION}"
        XCODE_ATTRIBUTE_PRODUCT_BUNDLE_IDENTIFIER "com.janhagenclausen.DecenzaPocket.PowerWidget"
        XCODE_ATTRIBUTE_SKIP_INSTALL "YES"
        XCODE_ATTRIBUTE_SWIFT_VERSION "5.9"
    )

    if(DECENZA_WIDGET_PROFILE_SPECIFIER)
        set_target_properties(PowerWidgetExtension PROPERTIES
            XCODE_ATTRIBUTE_PROVISIONING_PROFILE_SPECIFIER
                "${DECENZA_WIDGET_PROFILE_SPECIFIER}"
        )
    endif()

    target_link_libraries(PowerWidgetExtension PRIVATE
        "-framework SwiftUI"
        "-framework WidgetKit"
    )

    set_target_properties(DecenzaPocket PROPERTIES
        MACOSX_BUNDLE_GUI_IDENTIFIER "com.janhagenclausen.DecenzaPocket"
        MACOSX_BUNDLE_BUNDLE_VERSION "${DECENZA_BUILD_NUMBER}"
        MACOSX_BUNDLE_SHORT_VERSION_STRING "${CMAKE_PROJECT_VERSION}"
        MACOSX_BUNDLE_INFO_PLIST "${CMAKE_CURRENT_SOURCE_DIR}/ios/Info.plist"
        XCODE_ATTRIBUTE_ASSETCATALOG_COMPILER_APPICON_NAME "AppIcon"
        XCODE_ATTRIBUTE_MARKETING_VERSION "${CMAKE_PROJECT_VERSION}"
        XCODE_ATTRIBUTE_CURRENT_PROJECT_VERSION "${DECENZA_BUILD_NUMBER}"
        XCODE_EMBED_APP_EXTENSIONS PowerWidgetExtension
        XCODE_EMBED_APP_EXTENSIONS_CODE_SIGN_ON_COPY "YES"
        XCODE_EMBED_APP_EXTENSIONS_REMOVE_HEADERS_ON_COPY "YES"
    )

    if(DECENZA_MAIN_PROFILE_SPECIFIER)
        set_target_properties(DecenzaPocket PROPERTIES
            XCODE_ATTRIBUTE_PROVISIONING_PROFILE_SPECIFIER
                "${DECENZA_MAIN_PROFILE_SPECIFIER}"
        )
    endif()

    set_target_properties(DecenzaPocket PROPERTIES
        XCODE_ATTRIBUTE_CODE_SIGN_ENTITLEMENTS "${CMAKE_CURRENT_SOURCE_DIR}/ios/DecenzaPocket.entitlements"
    )

    # Add iOS asset catalog for app icon
    target_sources(DecenzaPocket PRIVATE
        "${CMAKE_CURRENT_SOURCE_DIR}/ios/Assets.xcassets"
    )
    set_source_files_properties(
        "${CMAKE_CURRENT_SOURCE_DIR}/ios/Assets.xcassets"
        PROPERTIES MACOSX_PACKAGE_LOCATION Resources
    )
    # Add privacy manifest (required for App Store since spring 2024)
    target_sources(DecenzaPocket PRIVATE
        "${CMAKE_CURRENT_SOURCE_DIR}/ios/PrivacyInfo.xcprivacy"
    )
    set_source_files_properties(
        "${CMAKE_CURRENT_SOURCE_DIR}/ios/PrivacyInfo.xcprivacy"
        PROPERTIES MACOSX_PACKAGE_LOCATION Resources
    )

    # Use native AVFoundation backend only (no FFmpeg)
    qt_import_plugins(DecenzaPocket
        INCLUDE_BY_TYPE multimedia Qt6::QDarwinMediaPlugin
        INCLUDE_BY_TYPE imageformats Qt6::QWebpPlugin Qt6::QSvgPlugin
    )

    target_link_libraries(DecenzaPocket PRIVATE
        "-framework AVFoundation"
        "-framework CoreAudio"
        "-framework AudioToolbox"
    )
endif()
