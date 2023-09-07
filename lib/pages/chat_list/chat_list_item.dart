import 'package:flutter/material.dart';

import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:future_loading_dialog/future_loading_dialog.dart';
import 'package:matrix/matrix.dart';
import 'package:vrouter/vrouter.dart';

import 'package:fluffychat/config/app_config.dart';
import 'package:fluffychat/utils/matrix_sdk_extensions/matrix_locals.dart';
import 'package:fluffychat/utils/room_status_extension.dart';
import '../../config/themes.dart';
import '../../utils/date_time_extension.dart';
import '../../widgets/avatar.dart';
import '../../widgets/matrix.dart';
import '../chat/send_file_dialog.dart';

enum ArchivedRoomAction { delete, rejoin }

class ChatListItem extends StatelessWidget {
  final Room room;
  final bool activeChat;
  final bool selected;
  final void Function()? onTap;
  final void Function()? onLongPress;

  const ChatListItem(
    this.room, {
    this.activeChat = false,
    this.selected = false,
    this.onTap,
    this.onLongPress,
    Key? key,
  }) : super(key: key);

  void clickAction(BuildContext context) async {
    if (onTap != null) return onTap!();
    if (activeChat) return;
    if (room.membership == Membership.invite) {
      final joinResult = await showFutureLoadingDialog(
        context: context,
        future: () async {
          final waitForRoom = room.client.waitForRoomInSync(
            room.id,
            join: true,
          );
          await room.join();
          await waitForRoom;
        },
      );
      if (joinResult.error != null) return;
    }

    if (room.membership == Membership.ban) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(L10n.of(context)!.youHaveBeenBannedFromThisChat),
        ),
      );
      return;
    }

    if (room.membership == Membership.leave) {
      VRouter.of(context).toSegments(['archive', room.id]);
    }

    if (room.membership == Membership.join) {
      // Share content into this room
      final shareContent = Matrix.of(context).shareContent;
      if (shareContent != null) {
        if (await showOkCancelAlertDialog(
              useRootNavigator: false,
              context: context,
              title: L10n.of(context)!.areYouSureYouWantToForward(room.name),
              okLabel: L10n.of(context)!.ok,
              cancelLabel: L10n.of(context)!.cancel,
            ) ==
            OkCancelResult.cancel) {
          return;
        }

        final shareFile = shareContent.tryGet<MatrixFile>('file');
        if (shareContent.tryGet<String>('msgtype') ==
                'chat.fluffy.shared_file' &&
            shareFile != null) {
          await showDialog(
            context: context,
            useRootNavigator: false,
            builder: (c) => SendFileDialog(
              files: [shareFile],
              room: room,
              requireReadReceipt: false,
            ),
          );
        } else {
          final forwardContent = _forwardContent(shareContent, context);
          room.sendEvent(forwardContent);
        }
        Matrix.of(context).shareContent = null;
      }

      VRouter.of(context).toSegments(['rooms', room.id]);
    }
  }

  Map<String, dynamic> _forwardContent(
    Map<String, dynamic> shareContent,
    BuildContext context,
  ) {
    if (shareContent.tryGet<String>('msgtype') != MessageTypes.Text) {
      // add forwarded-text only if message is o type m.text otherwise return
      return shareContent;
    }

    final forwardText = '<i>${L10n.of(context)!.forwardedMessage}</i><br>';
    String? body = "";

    if (shareContent.containsKey('body')) {
      body = shareContent.tryGet<String>('body');
      body ??= "";

      if (body.startsWith(L10n.of(context)!.forwardedMessage)) {
        // don't add forwarded-text twice
        return shareContent;
      }

      shareContent['body'] = '${L10n.of(context)!.forwardedMessage}\n$body';
    } else {
      shareContent.addAll({'body': L10n.of(context)!.forwardedMessage});
    }

    if (shareContent.containsKey('formatted_body')) {
      final formattedBody = shareContent.tryGet<String>('formatted_body')!;

      /* text forwarded-text appears after citation, should be before citation
         don't add forwarded-text to message with reply? if yes, uncomment the following lines!
      if(formattedBody.contains('<mx-reply>')) {
        return shareContent;
      }
      */
      shareContent['formatted_body'] = '$forwardText$formattedBody';
    } else {
      shareContent.addAll({
        'formatted_body': '$forwardText$body',
      });
    }

    if (shareContent.containsKey('format')) {
      shareContent['format'] = 'org.matrix.custom.html';
    } else {
      shareContent.addAll({'format': 'org.matrix.custom.html'});
    }

    return shareContent;
  }

  Future<void> archiveAction(BuildContext context) async {
    {
      if ([Membership.leave, Membership.ban].contains(room.membership)) {
        await showFutureLoadingDialog(
          context: context,
          future: () => room.forget(),
        );
        return;
      }
      final confirmed = await showOkCancelAlertDialog(
        useRootNavigator: false,
        context: context,
        title: L10n.of(context)!.areYouSure,
        okLabel: L10n.of(context)!.yes,
        cancelLabel: L10n.of(context)!.no,
      );
      if (confirmed == OkCancelResult.cancel) return;
      await showFutureLoadingDialog(
        context: context,
        future: () => room.leave(),
      );
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMuted = room.pushRuleState != PushRuleState.notify;
    final typingText = room.getLocalizedTypingText(context);
    final ownMessage =
        room.lastEvent?.senderId == Matrix.of(context).client.userID;
    final unread = room.isUnread || room.membership == Membership.invite;
    final unreadBubbleSize = unread || room.hasNewMessages
        ? room.notificationCount > 0
            ? 20.0
            : 14.0
        : 0.0;
    final displayname = room.getLocalizedDisplayname(
      MatrixLocals(L10n.of(context)!),
    );
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 1,
      ),
      child: Material(
        borderRadius: BorderRadius.circular(AppConfig.borderRadius),
        clipBehavior: Clip.hardEdge,
        color: selected
            ? Theme.of(context).colorScheme.primaryContainer
            : activeChat
                ? Theme.of(context).colorScheme.secondaryContainer
                : Colors.transparent,
        child: ListTile(
          visualDensity: const VisualDensity(vertical: -0.5),
          contentPadding: const EdgeInsets.symmetric(horizontal: 8),
          onLongPress: onLongPress,
          leading: selected
              ? SizedBox(
                  width: Avatar.defaultSize,
                  height: Avatar.defaultSize,
                  child: Material(
                    color: Theme.of(context).primaryColor,
                    borderRadius: BorderRadius.circular(Avatar.defaultSize),
                    child: const Icon(Icons.check, color: Colors.white),
                  ),
                )
              : Avatar(
                  mxContent: room.avatar,
                  name: displayname,
                  onTap: onLongPress,
                ),
          title: Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  displayname,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  softWrap: false,
                  style: TextStyle(
                    fontWeight: unread ? FontWeight.bold : null,
                  ),
                ),
              ),
              if (isMuted)
                const Padding(
                  padding: EdgeInsets.only(left: 4.0),
                  child: Icon(
                    Icons.notifications_off_outlined,
                    size: 16,
                  ),
                ),
              if (room.isFavourite)
                Padding(
                  padding: EdgeInsets.only(
                    right: room.notificationCount > 0 ? 4.0 : 0.0,
                  ),
                  child: Icon(
                    Icons.push_pin,
                    size: 16,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              Padding(
                padding: const EdgeInsets.only(left: 4.0),
                child: Text(
                  room.timeCreated.localizedTimeShort(context),
                  style: TextStyle(
                    fontSize: 13,
                    color: unread
                        ? Theme.of(context).colorScheme.secondary
                        : Theme.of(context).textTheme.bodyMedium!.color,
                  ),
                ),
              ),
            ],
          ),
          subtitle: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              if (typingText.isEmpty &&
                  ownMessage &&
                  room.lastEvent!.status.isSending) ...[
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator.adaptive(strokeWidth: 2),
                ),
                const SizedBox(width: 4),
              ],
              AnimatedContainer(
                width: typingText.isEmpty ? 0 : 18,
                clipBehavior: Clip.hardEdge,
                decoration: const BoxDecoration(),
                duration: FluffyThemes.animationDuration,
                curve: FluffyThemes.animationCurve,
                padding: const EdgeInsets.only(right: 4),
                child: Icon(
                  Icons.edit_outlined,
                  color: Theme.of(context).colorScheme.secondary,
                  size: 14,
                ),
              ),
              Expanded(
                child: typingText.isNotEmpty
                    ? Text(
                        typingText,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        maxLines: 1,
                        softWrap: false,
                      )
                    : FutureBuilder<String>(
                        future: room.lastEvent?.calcLocalizedBody(
                              MatrixLocals(L10n.of(context)!),
                              hideReply: true,
                              hideEdit: true,
                              plaintextBody: true,
                              removeMarkdown: true,
                              withSenderNamePrefix: !room.isDirectChat ||
                                  room.directChatMatrixID !=
                                      room.lastEvent?.senderId,
                            ) ??
                            Future.value(L10n.of(context)!.emptyChat),
                        builder: (context, snapshot) {
                          return Text(
                            room.membership == Membership.invite
                                ? L10n.of(context)!.youAreInvitedToThisChat
                                : snapshot.data ??
                                    room.lastEvent?.calcLocalizedBodyFallback(
                                      MatrixLocals(L10n.of(context)!),
                                      hideReply: true,
                                      hideEdit: true,
                                      plaintextBody: true,
                                      removeMarkdown: true,
                                      withSenderNamePrefix:
                                          !room.isDirectChat ||
                                              room.directChatMatrixID !=
                                                  room.lastEvent?.senderId,
                                    ) ??
                                    L10n.of(context)!.emptyChat,
                            softWrap: false,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontWeight: unread ? FontWeight.w600 : null,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                              decoration: room.lastEvent?.redacted == true
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                          );
                        },
                      ),
              ),
              const SizedBox(width: 8),
              AnimatedContainer(
                duration: FluffyThemes.animationDuration,
                curve: FluffyThemes.animationCurve,
                padding: const EdgeInsets.symmetric(horizontal: 7),
                height: unreadBubbleSize,
                width: room.notificationCount == 0 &&
                        !unread &&
                        !room.hasNewMessages
                    ? 0
                    : (unreadBubbleSize - 9) *
                            room.notificationCount.toString().length +
                        9,
                decoration: BoxDecoration(
                  color: room.highlightCount > 0 ||
                          room.membership == Membership.invite
                      ? Colors.red
                      : room.notificationCount > 0 || room.markedUnread
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(AppConfig.borderRadius),
                ),
                child: Center(
                  child: room.notificationCount > 0
                      ? Text(
                          room.notificationCount.toString(),
                          style: TextStyle(
                            color: room.highlightCount > 0
                                ? Colors.white
                                : room.notificationCount > 0
                                    ? Theme.of(context).colorScheme.onPrimary
                                    : Theme.of(context)
                                        .colorScheme
                                        .onPrimaryContainer,
                            fontSize: 13,
                          ),
                        )
                      : Container(),
                ),
              ),
            ],
          ),
          onTap: () => clickAction(context),
        ),
      ),
    );
  }
}
