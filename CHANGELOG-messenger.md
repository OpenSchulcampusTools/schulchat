# Next release

Feature: Filter contacts by school in case a room already has contacts.
Feature: Filter contacts by school in case a school is selected in chat list.

Fix: Sending messages on Enter (web).
Fix: Don't show invite menu if user has no permission to invite others.
Fix: Chat list does not show school icon if there is only one school (android/iOS)

Misc: UI improvements in addressbook

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
