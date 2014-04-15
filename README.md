kickflip-ios-example
====================

[![kickflip app screenshot](https://i.imgur.com/QPtggd9m.jpg)](https://i.imgur.com/QPtggd9.png)
[![kickflip live broadcast screenshot](https://i.imgur.com/VHB6iQQm.jpg)](https://i.imgur.com/VHB6iQQ.png)
[![kickflip live consumption screenshot](https://i.imgur.com/IZbiyhRm.jpg)](https://i.imgur.com/IZbiyhR.png)

[Screenshots Gallery](http://imgur.com/a/IwuZ7)

Example project for integration of the [Kickflip iOS SDK](https://github.com/Kickflip/kickflip-ios-sdk) for super easy live broadcasts. We have an [example project for Android](https://github.com/kickflip/kickflip-android-example) as well.
    
## Cocoapods Setup

You'll need to install [Cocoapods](http://cocoapods.org) first.
    
## Compiling

Grab the source code, and then update the dependencies.

	$ git clone git@github.com:Kickflip/kickflip-ios-example.git
    $ cd kickflip-ios-example
    $ git submodule update --init
    $ pod
    
If you would like to make modifications to the core SDK, you can integrate the SDK as a submodule as well (check the `Podfile` for more info).

## KFSecrets.h

You'll need to [sign up](https://kickflip.io), make a new app, and then put your API keys from  and put them in a file called `KFSecrets.h` with the following contents:

	#define KICKFLIP_API_KEY @"Client ID from kickflip.io"
	#define KICKFLIP_API_SECRET @"Client Secret from kickflip.io"

## License

Apache 2.0

## Attribution

* [Info](http://icons8.com/icons/#!/77/info) by [Icons 8](http://icons8.com) ([CC BY-ND 3.0](http://creativecommons.org/licenses/by-nd/3.0/))
* [Camera Video](https://www.iconfinder.com/icons/172629/camera_video_icon) by [Icons 8](http://icons8.com) ([CC BY-ND 3.0](http://creativecommons.org/licenses/by-nd/3.0/))