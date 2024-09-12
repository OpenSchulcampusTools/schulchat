# 25

Change: Do not request profile information of bot

# 24.0.1

Change: Better error handling during QR-Code Login (Android/iOS)

# 24

Fix: SLO in Schulcampus when using the web client

Change: Revert: Clear local data from SchulchatRLP before logging out from SC (Regression)


# 23

Add: Polls

Change: idpLogoutURL from SAML2 to OAuth2
Change: Clear local data from SchulchatRLP before logging out from SC

Fix: Logout using FlutterWebAuth instead of launchUrl


# 22

Added: Add a notice for users to remember to logout when sharing a device
Fix: Role Schulsozialarbeit was not shown in addressbook
Fix: Invite groups on iOS
Fix: Logout URL link was pointing to dev env
Fix: QR-Code-Login was not working in dev env (k8s)

# 21

Added: possibility to remove group from room
Added: possibility to leave a room, removing all groups/users first
Change: Help/support link
Fix: prevent setting schoolid during new invites

# 20
Feature: Logout gleichzeitig im Schulcampus

# 19

Fix: mime types on iOS
Misc: Several UI improvements

# 18

Change: Adressbook remove refresh button, when invite button is visible.
Change: Drop telecom connection service on android

Misc: Fix integration tests

# 16

Fix: Repair QRcode-Login

# 15

Change: Sort scgroups by name in addressbook
Change: Adapt links (privacy etc)

Misc: Disable encryption button for the moment until we have a better UI for devices/verification/blocking

# 13

Feature: Highlight forwarded messages
Feature: Prevent admins from leaving rooms in case there is no other admin

Fix: Show edited messages in Read Receipt Overview

Misc: Don't show idm bot in room info

# 12

Feature: Show 'new chat' in Profile/user bottom sheet in case the user has permission to send messages to the other user

Misc: Only use roles moderator/user
Misc: Don't strikethrough users that are not enabled yet; instead use italic style

Chore: adapt privacy url
Chore: Rename package to Schulchat

# 11

Fix: Messages are sent multiple times (sendOnEnter bug)
Fix: Clip long group/user names in addressbook onto new line
Fix: Back arrow in Read Receipts (UX, dark mode)

Misc: Remove voip code
Misc: Reload addressbook whenever it is used
Misc: Open chats by default instead of messages

# 10

Feature: Error handling for read receipts
Feature: Add dialog to confirm message forwards
Feature: Support editing of messages with read receipts (announcements)
Feature: Log client errors to server

Fix: Leaving a room clears all read receipt requests
Fix: Role labels in rooms could not be read (UX)
Fix: Don't show read receipt button when editing messages
Fix: Don't display message source and sender in event details (UX)
Fix: Don't display password change method, as this is done within IdP
Fix: Read receipt localization in Push messages
Fix: School identifier message localization

Misc: Don't display message details (Push, Android)
Misc: Push localization
Misc: Enable send on enter by default
Misc: Enable hide unknown events by default
Misc: Use 'Schulchat' in more places (branding)
Misc: Remove invite button from settings
Misc: Clip too long text in addressbook

Chore: Bump chromedriver

# test9
Feature: Adapt Design

Fix: Temporarly remove New chat feature from user profile and room participant info sheet
Fix: Remove possibility to change display name
Fix: Remove possibility to change your own avatar (set globally in Schulcampus instead)
Fix: Prevent setting room to public

# test8
Fix: Delete messages from input bar in case they have been sent. Accidentally missed some lines during merge, as we had changes on the same lines.

# test7

Feature: Adapt branding
Fix: Prevent fetching fonts from Google

# test6

Feature: Add refresh functionality in addressbook.

# test5

Feature: Filter contacts by school in case a room already has contacts.
Feature: Filter contacts by school in case a school is selected in chat list.

Fix: Sending messages on Enter (web).
Fix: Don't show invite menu if user has no permission to invite others.
Fix: Chat list does not show school icon if there is only one school (android/iOS)

Misc: UI improvements in addressbook, add labels

Chore: localization updates

# test4

Feature: Add icons in chat list for all schools.
Feature: Store school id as state event in room. This helps implementing the report feature.

Fix: Cache addressbook in hive, which reduces the number of requests.

# test3

Feature: Option for read-only rooms during room creation

Fix: Various localization updates
Fix: Don't skip all other invitees, if there is an error during invitation of one of them.
Fix: Remove possibility to login with user/password without Schulcampus
Fix: Jump to selected search results on large screen

Chore: Remove stories
Chore: Remove spaces
Chore: Various improvements of CI

# test2

Feature: deselecting group members; it is possible to remove specific users when adding groups. This will prevent the resulting memberships from being synced with IDM.

Fix: Do not display special SCGroup rooms. Those rooms are a 1:1 mapping between an individual IDM group and matrix users.
Fix: Do not display 'Invite via Address book' if the user has no permission to invite other users. By default, only an user with power level 50 can invite other users.
