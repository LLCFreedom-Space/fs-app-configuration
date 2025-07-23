# Get App Configuration

Quick implementation of getting the application status.

## Swift version

The latest version of FSAppConfiguration requires **Swift 6.0** and **MacOS v14** or later. You can download this version of the Swift binaries by following this [link](https://swift.org/download/).

## Usage

### Swift Package Manager

#### Add dependencies using the version
Add the `FSAppConfiguration` package to the dependencies within your application’s `Package.swift` file. Substitute `"x.x.x"` with the latest `FSAppConfiguration` [release](https://github.com/LLCFreedom-Space/fs-app-configuration/releases).
```swift
.package(url: "https://github.com/LLCFreedom-Space/fs-app-configuration.git", from: "x.x.x")
```
Add `FSAppConfiguration` to your target's dependencies:
```swift
.target(name: "FSAppConfiguration", dependencies: ["FSAppConfiguration"]),
```
#### Import package
```swift
import FSAppConfiguration
```

#### Add dependencies using the branch
Add the `FSAppConfiguration` package to the dependencies within your application’s `Package.swift` file. Substitute `"name branch"` with the latest `FSAppConfiguration` [release](https://github.com/LLCFreedom-Space/fs-app-configuration/releases).
```swift
.package(url: "https://github.com/LLCFreedom-Space/fs-app-configuration.git", branch: "name branch")
```
Add `FSAppConfiguration` to your target's dependencies:
```swift
.target(name: "FSAppConfiguration", dependencies: ["FSAppConfiguration"]),
```
#### Import package
```swift
import FSAppConfiguration
```

## Getting Started
An example of a method call from this library 
```
app.appStatus.getRedisStatus()
```
To access the methods that are in this library, you need to call the application, since this library is an extension to the application

## API Documentation
There are functions that are used in a pair. Example:
```
func applicationLaunchTime vs func applicationLaunchDate
```
need use when you configuration your Application. In last line in configure.swift file. Because this function records the start time in the application.
And the function where you need to understand how long the application has been running since it started.
```
func applicationUpTime vs func applicationUpDate
``` 
Depending on which value you want, you call one or the second function.
