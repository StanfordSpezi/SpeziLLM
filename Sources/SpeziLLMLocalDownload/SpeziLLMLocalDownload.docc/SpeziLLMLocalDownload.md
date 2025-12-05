# ``SpeziLLMLocalDownload``

<!--
#
# This source file is part of the Stanford Spezi open source project
#
# SPDX-FileCopyrightText: 2023 Stanford University and the project authors (see CONTRIBUTORS.md)
#
# SPDX-License-Identifier: MIT
#       
-->

Provides download and storage functionality for Large Language Models (LLMs).

## Overview

The ``SpeziLLMLocalDownload`` target provides download and storage functionality for Large Language Models (LLMs) to the local device in the Spezi ecosystem. As Language Models typically have big file sizes and therefore long transmission times, the download process has to be properly managed with care. ``SpeziLLMLocalDownload`` offers reusable view- and manager components for developers to easily achieve their desired local LLM setup process in an application.

## Setup

### Add Spezi LLM as a Dependency

You need to add the SpeziLLM Swift package to
[your app in Xcode](https://developer.apple.com/documentation/xcode/adding-package-dependencies-to-your-app#) or
[Swift package](https://developer.apple.com/documentation/xcode/creating-a-standalone-swift-package-with-xcode#Add-a-dependency-on-another-Swift-package).

> Important: If your application is not yet configured to use Spezi, follow the [Spezi setup article](https://swiftpackageindex.com/stanfordspezi/spezi/documentation/spezi/initial-setup) to set up the core Spezi infrastructure.

## Spezi LLM Local Download Components

The two main components of ``SpeziLLMLocalDownload`` are the ``LLMLocalDownloadView`` providing an out-of-the-box onboarding view to download large models and the ``LLMLocalDownloadManager`` that contains all the logic for the model download and local storage.

### Download View

The ``LLMLocalDownloadView`` provides an out-of-the-box onboarding view for downloading locally executed [SpeziLLM](https://swiftpackageindex.com/stanfordspezi/spezillm/documentation/spezillm) LLMs to the device.
It can be combined with the [SpeziViews](https://swiftpackageindex.com/stanfordspezi/speziviews/documentation) [`ManagedNavigationStack`](https://swiftpackageindex.com/stanfordspezi/speziviews/documentation/speziviews/managednavigationstack) to create an easy onboarding flow within the application.
The ``LLMLocalDownloadView`` automatically checks if the model already exists on disk, and if not, offers the start of the download via a button click. The download process itself includes the presentation of a percentage progress view in order to give the user a better feeling for the download progress.

The ``LLMLocalDownloadView/init(model:downloadDescription:action:)-4a14v`` initializer accepts a download description displayed in the view, the remote download `URL` of the LLM, the local storage `URL` of the downloaded model, as well as an action closure to move onto the next (onboarding) step.

The heavy lifting of downloading and storing the model is done by the ``LLMLocalDownloadManager`` which exposes the current downloading state view the ``LLMLocalDownloadManager/state`` property of type ``LLMLocalDownloadManager/DownloadState``.

#### Usage

The code example below creates an onboarding flow via the [SpeziViews](https://swiftpackageindex.com/stanfordspezi/speziviews/documentation) [`ManagedNavigationStack`](https://swiftpackageindex.com/stanfordspezi/speziviews/documentation/speziviews/managednavigationstack) that downloads and stores an Language Model on the local device via the use of the ``LLMLocalDownloadView``.

```swift
struct LLMLocalDownloadApp: View {
    var body: some View {
        ManagedNavigationStack {
            LLMLocalOnboardingDownloadView()
        }
    }
}
```

```swift
struct LLMLocalOnboardingDownloadView: View {
    @Environment(ManagedNavigationStack.Path.self) private var onboardingNavigationPath

    var body: some View {
        LLMLocalDownloadView(
            model: .llama3_8B_4bit,
            downloadDescription: "The Llama3 8B model will be downloaded"
        ) {
            onboardingNavigationPath.nextStep()
        }
    }
}
```

### Download Manager

The ``LLMLocalDownloadManager`` manages the download and storage of Large Language Models to the local device.

One configures the ``LLMLocalDownloadManager`` via the ``LLMLocalDownloadManager/init(model:)`` initializer,
passing a download `URL` as well as a local storage `URL` to the ``LLMLocalDownloadManager``.
The download of a model is started via ``LLMLocalDownloadManager/startDownload()`` and can be cancelled (early) via ``LLMLocalDownloadManager/cancelDownload()``.

The current state of the ``LLMLocalDownloadManager`` is exposed via the ``LLMLocalDownloadManager/state`` property which
is of type ``LLMLocalDownloadManager/DownloadState``, containing states such as ``LLMLocalDownloadManager/DownloadState/downloading(progress:)`` which includes the progress of the download or ``LLMLocalDownloadManager/DownloadState/downloaded`` which indicates that the download has finished.

## Topics

### Views

- ``LLMLocalDownloadView``

### Operations

- ``LLMLocalDownloadManager``
