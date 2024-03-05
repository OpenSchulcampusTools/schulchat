![](https://i.imgur.com/wi7RlVt.png)

<p align="center">
  <a href="https://matrix.to/#/#fluffychat:matrix.org" target="new">Join the community</a> - <a href="https://metalhead.club/@krille" target="new">Follow me on Mastodon</a> - <a href="https://hosted.weblate.org/projects/fluffychat/" target="new">Translate FluffyChat</a> - <a href="https://gitlab.com/ChristianPauly/fluffychat-website" target="new">Translate the website</a> - <a href="https://fluffychat.im" target="new">Website</a> - <a href="https://gitlab.com/famedly/famedlysdk" target="new">Famedly Matrix SDK</a> - <a href="https://famedly.com/kontakt">Server hosting and professional support</a>
 </p>


FluffyChat is an open source, nonprofit and cute matrix messenger app. The app is easy to use but secure and decentralized.

## Features

- Send all kinds of messages, images and files
- Voice messages
- Location sharing
- Push notifications
- Unlimited private and public group chats
- Public channels with thousands of participants
- Feature rich group moderation including all matrix features
- Discover and join public groups
- Dark mode
- Custom themes
- Hides complexity of Matrix IDs behind simple QR codes
- Custom emotes and stickers
- Spaces
- Compatible with Element, Nheko, NeoChat and all other Matrix apps
- End to end encryption
- Emoji verification & cross signing
- And much more...

# Installation

Please visit our website for installation instructions:

https://fluffychat.im

# How to build

Please visit our Wiki for build instructions:

https://gitlab.com/famedly/fluffychat/-/wikis/How-To-Build

# Building a docker image

## Install flutter

In addition to the installation instruction on the flutter website mentioned above, keep in mind that the dart sdk 
version must be in the range defined in pubspec.yaml => environment => sdk

```yaml
...
environment:
  sdk: ">= min_version < max_version"
...
```
On the [flutter download page](https://docs.flutter.dev/release/archive), look in the "Stable channel (Linux)" tab. The 
dart version is in the second column from the right. 

For example, if the sdk version is defined as `">=2.17.0 <3.0.0"`, you'd want the flutter distribution that contains the 
latest 2.x-based dart sdk, in this case flutter 3.7.12 (dart sdk 2.19.6).

Download the archive and install it using [the instruction on the flutter website](https://docs.flutter.dev/get-started/install/linux#method-2-manual-installation).

## Set up and build fluffychat

There are two scripts that take of the build process. Run these sequentially:

```
./scripts/prepare-web.sh
./scripts/build-web.sh
```

This will yield a "build" directory containing the freshly built web client. 

## Build docker image

There is a dockerfile that can be used to take care of the rest of the build process:

```shell
docker build -t <tag> -f docker/Dockerfile.web
```

## Add docker file to the container registry

```shell
docker push <tag>
```

## Add docker image from artifacts to registry

Download the artifact from the `build_docker` job. It is zipped by default, so first unzip, then gzip -d.

```shell
docker image import docker_image_web registry.fairkom.net/clients/rlp/client/fluffychat:22.0.3_36-a7a35c2b
```

# Special thanks

* <a href="https://github.com/fabiyamada">Fabiyamada</a> is a graphics designer from Brasil and has made the fluffychat logo and the banner. Big thanks for her great designs.

* <a href="https://github.com/advocatux">Advocatux</a> has made the Spanish translation with great love and care. He always stands by my side and supports my work with great commitment.

* Thanks to MTRNord and Sorunome for developing.

* Also thanks to all translators and testers! With your help, fluffychat is now available in more than 12 languages.

* <a href="https://github.com/googlefonts/noto-emoji/">Noto Emoji Font</a> for the awesome emojis.

* <a href="https://github.com/madsrh/WoodenBeaver">WoodenBeaver</a> sound theme for the notification sound.

* The Matrix Foundation for making and maintaining the [emoji translations](https://github.com/matrix-org/matrix-doc/blob/main/data-definitions/sas-emoji.json) used for emoji verification, licensed Apache 2.0
