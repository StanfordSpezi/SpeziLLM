<!--
                  
This source file is part of the TemplatePackage open source project

SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)

SPDX-License-Identifier: MIT
             
-->

# TemplatePackage

[![Build and Test](https://github.com/StanfordBDHG/SwiftPackageTemplate/actions/workflows/build-and-test.yml/badge.svg)](https://github.com/StanfordBDHG/SwiftPackageTemplate/actions/workflows/build-and-test.yml)
[![codecov](https://codecov.io/gh/StanfordBDHG/SwiftPackageTemplate/branch/main/graph/badge.svg?token=X7BQYSUKOH)](https://codecov.io/gh/StanfordBDHG/SwiftPackageTemplate)
[![DOI](https://zenodo.org/badge/573230182.svg)](https://zenodo.org/badge/latestdoi/573230182)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2FStanfordBDHG%2FSwiftPackageTemplate%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/StanfordBDHG/SwiftPackageTemplate)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2FStanfordBDHG%2FSwiftPackageTemplate%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/StanfordBDHG/SwiftPackageTemplate)


## How To Use This Template

The template repository contains a template Swift Package, including a continuous integration setup. Follow these steps to customize it to your needs:
1. Rename the Swift Package. Be sure that you update the name in the `build-and-test.yml` GitHub Action accordingly. If you have multiple targets in your Swift Package, you need to pass the name of the Swift Package followed by an `-Package` as the scheme to the GitHub Action, e.g., `StanfordProject-Package` if your Swift Package is named `StanfordProject`.
2. If your Swift Package does not provide any user interface or does not require an iOS application environment to function, you can remove the `UITests` application from the `Tests` folder. You need to update the `build-and-test.yml` GitHub Action accordingly by removing the GitHub Action that builds and tests the application, removing the dependency from the code coverage upload step, and removing the UI test `.xresult` input from the code coverage test.
3. You will either need to add the [CodeCov GitHub App](https://github.com/apps/codecov) or add a codecov.io token to your [GitHub Actions Secrets](https://docs.github.com/en/actions/security-guides/encrypted-secrets#creating-encrypted-secrets-for-an-environment) following the instructions of the [Codecov GitHub Action](https://github.com/marketplace/actions/codecov#usage). The StanfordBDHG organization already has the [CodeCov GitHub App](https://github.com/apps/codecov) installed. If you do not want to cover test coverage data, you can remove the code coverage job in the `build-and-test.yml` GitHub Action.
4. Adjust this README to describe your project and adjust the badges at the top to point to the correct GitHub Action of your repository and Codecov badge.
5. The Swift Package template includes a Swift Package Index configuration file to automatically build the package and [host the documentation on the Swift Package Index website](https://blog.swiftpackageindex.com/posts/auto-generating-auto-hosting-and-auto-updating-docc-documentation/). Adjust the `.spi.yml` file to include all targets that you want to build documentation for. You can follow the [instructions of the Swift Package Index](https://swiftpackageindex.com/add-a-package) to include your Swift Package in the Swift Package Index. You can link to the [API documentation](https://swiftpackageindex.com/StanfordBDHG/SwiftPackageTemplate/documentation) from your README file.
6. Adjust the CITATION.cff file to admend information about the new Swift Package ([learn more about CITATION files on GitHub](https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/customizing-your-repository/about-citation-files)) and [register the Swift Package on Zenodo](https://docs.github.com/en/repositories/archiving-a-github-repository/referencing-and-citing-content). 


## Installation

The project can be added to your Xcode project or Swift Package using the [Swift Package Manager](https://github.com/apple/swift-package-manager).

**Xcode:** For an Xcode project, follow the instructions on [adding package dependencies to your app](https://developer.apple.com/documentation/xcode/adding-package-dependencies-to-your-app).

**Swift Package:** You can follow the [Swift Package Manager documentation about defining dependencies](https://github.com/apple/swift-package-manager/blob/main/Documentation/Usage.md#defining-dependencies) to add this project as a dependency to your Swift Package.


## License
This project is licensed under the MIT License. See [Licenses](https://github.com/StanfordBDHG/TemplatePackage/tree/main/LICENSES) for more information.


## Contributors
This project is developed as part of the Stanford Byers Center for Biodesign at Stanford University.
See [CONTRIBUTORS.md](https://github.com/StanfordBDHG/TemplatePackage/tree/main/CONTRIBUTORS.md) for a full list of all TemplatePackage contributors.

![Stanford Byers Center for Biodesign Logo](https://raw.githubusercontent.com/StanfordBDHG/.github/main/assets/biodesign-footer-light.png#gh-light-mode-only)
![Stanford Byers Center for Biodesign Logo](https://raw.githubusercontent.com/StanfordBDHG/.github/main/assets/biodesign-footer-dark.png#gh-dark-mode-only)
