# applozic-ios-video-call-sample-code

Project contains Applozic.framework supporting Audio, Video call with sample in Objective C.

### Installing lfs

i)  To fetch framowrk files(larger-file), you need to install lfs. You can install it by running bewlo command:

```
brew install git-lfs 
```
ii)  You can verify installation was successful, by running below command on terminal.

```
git lfs install
```

iii) Once you complete checkout of sample-repo, go to project's root folder and run below command:

```
git lfs pull
```



## Integration Steps: 

##### 1) navigate to your Xcode project's General settings page and add Applozic.framework,Twillio.framework from [sample project root folder](https://github.com/AppLozic/applozic-ios-video-call-sample/tree/master/ALAudioVideo) as Embeded binaries.

#### 2) Add below libraries in Linked Frameworks and Libraries.

- AudioToolbox.framework
- VideoToolbox.framework
- AVFoundation.framework
- CoreTelephony.framework
- GLKit.framework
- CoreMedia.framework
- SystemConfiguration.framework
- libc++.tbd

#### 3) Add Audio/Video code to your project.
 - Copy paste [AudioVideo](https://github.com/AppLozic/applozic-ios-video-call-sample/tree/master/ALAudioVideo/ALAudioVideo/AudioVideo) folder from sample project and paste it into your root directory of your project. Go to Add Files to project, select all files present in Folder and add it to your project.

#### 4) Follow basic integration steps:
- After above steps, follow our documentaion page from steps 2) onward for integration:

https://www.applozic.com/docs/ios-chat-sdk.html#step-2-login-register-user

#### 5) Notification setup:

      
 
#### 5) Add below setting in ALChatManger.m's in ALDefaultChatViewSettings.

    [ALApplozicSettings setAudioVideoClassName:@"ALAudioVideoCallVC"];
    
