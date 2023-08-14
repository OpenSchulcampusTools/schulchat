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
