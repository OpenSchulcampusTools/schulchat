# Next version test3

Feature: Option for read-only rooms during room creation

Fix: Various localization updates
Fix: Don't skip all other invitees, if there is an error during invitation of one of them.

Chore: Remove stories
Chore: Remove spaces

# test2

Feature: deselecting group members; it is possible to remove specific users when adding groups. This will prevent the resulting memberships from being synced with IDM.

Fix: Do not display special SCGroup rooms. Those rooms are a 1:1 mapping between an individual IDM group and matrix users.
Fix: Do not display 'Invite via Address book' if the user has no permission to invite other users. By default, only an user with power level 50 can invite other users.
