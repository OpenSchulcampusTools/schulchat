import 'package:matrix/matrix.dart';

/*
* returns eventId if a new ReadReceipt-event was created,
* otherwise returns null
 */
extension PollExtension on Event {
  bool get isOwnEvent => (senderId == room.client.userID);

  Future<List<Event>> allResponses(Timeline timeline) async {
    final aggregatedResponses =
        aggregatedEvents(timeline, RelationshipTypes.pollResponse);

    final List<Event> responses = [];
    for (final e in aggregatedResponses) {
      if (e.status != EventStatus.error && e.status != EventStatus.removed) {
        // _decrypt is necessary to display responses after login correct
        final response = await _decrypt(e);
        if (response.type == EventTypes.PollResponse) {
          responses.add(response);
        }
      }
    }
    return responses;
  }

  Future<Event> _decrypt(Event event) async {
    if (event.type == EventTypes.Encrypted &&
        event.room.client.encryptionEnabled) {
      event =
          await event.room.client.encryption!.decryptRoomEvent(room.id, event);
      if (event.type == EventTypes.Encrypted ||
          event.messageType == MessageTypes.BadEncrypted ||
          event.content['can_request_session'] == true) {
        // Await requestKey() here to ensure decrypted message bodies
        await event.requestKey();
        event = await event.room.client.encryption!
            .decryptRoomEvent(room.id, event);
      }
    }
    return event;
  }

  Event? getPollEndEvent(Timeline timeline) {
    final List<Event> endEvents =
        aggregatedEvents(timeline, RelationshipTypes.pollEnd)
            .where(
              (e) =>
                  e.status != EventStatus.error &&
                  e.status != EventStatus.removed,
            )
            .toList();

    if (endEvents.isNotEmpty) {
      return endEvents.first;
    } else {
      return null;
    }
  }

  String? getVoteId() {
    final selection = content.tryGetList<dynamic>('m.selections');
    if (selection != null && selection.isNotEmpty) {
      return selection.first;
    }

    return null;
  }

  Map<String, String> getAnswers() {
    final answers = content
        .tryGetMap<String, dynamic>("m.poll")
        ?.tryGetList<dynamic>('answers');
    final Map<String, String> answerMap = {};

    if (answers != null) {
      for (final answer in answers) {
        final id = answer["m.id"];
        final text = answer["m.text"][0]["body"];
        answerMap.addAll({id: text});
      }
    }

    return answerMap;
  }
}
