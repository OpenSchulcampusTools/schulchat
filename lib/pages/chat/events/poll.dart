import 'package:flutter/material.dart';

import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter_polls/flutter_polls.dart';
import 'package:matrix/matrix.dart';

import '../poll/poll_extension.dart';

class Poll extends StatelessWidget {
  final Event event;
  final Timeline timeline;
  final Future<bool> Function(Event, String?)? onVoted;

  String? question = "";
  bool freeText = false;
  bool showNames = false;
  int maxSelections = 1;
  bool isLivePoll = false;
  List<dynamic>? answers;

  Poll(
    this.event,
    this.timeline,
    this.onVoted, {
    Key? key,
  }) : super(key: key);

  void _readPoll() {
    final poll = event.content.tryGetMap<String, dynamic>("m.poll");

    if (poll != null) {
      final body = poll
          .tryGetMap<String, dynamic>('question')
          ?.tryGetList<dynamic>("m.text")
          ?.first;
      if (body != null) {
        question = body["body"];
      }

      answers = poll.tryGetList<dynamic>('answers');

      if (poll.tryGet<String>('free_text') == PollOptions.WithFreeText) {
        freeText = true;
      }

      if (poll.tryGet<String>('show_names') == PollOptions.WithNames) {
        showNames = true;
      }

      if (poll.tryGet<String>('kind') == PollOptions.IsLivePoll) {
        isLivePoll = true;
      }

      final tmpMax = poll.tryGet<int>('max_selections');
      if (tmpMax != null &&
          tmpMax > 0 &&
          answers != null &&
          tmpMax <= answers!.length) {
        maxSelections = tmpMax;
      }
    }
  }

  bool _isValidPoll() {
    return question != null &&
        question!.isNotEmpty &&
        answers != null &&
        answers!.length > 1;
  }

  int _getOptionVotes(String optionId, List<Event> responses) {
    final options = responses.where((Event e) {
      final selection = e.content.tryGetList<dynamic>('m.selections');
      if (selection != null) {
        return selection.contains(optionId);
      }
      return false;
    }).toList();

    return options.length;
  }

  Event? _userVote(List<Event> responses) {
    final String? userId = event.room.client.userID;

    if (userId != null) {
      for (final event in responses) {
        if (event.senderId == userId) {
          return event;
        }
      }
    }
    return null;
  }

  String? _getVoteId(List<Event> responses) {
    final Event? userVote = _userVote(responses);
    if (userVote != null) {
      return userVote.getVoteId();
    }
    return null;
  }

  List<PollOption> _makePollOptionsList(List<Event> responses) {
    final List<PollOption> options = [];

    if (answers != null) {
      for (final Map<String, dynamic> answer in answers!) {
        if (answer.containsKey("m.id")) {
          final id = answer["m.id"].toString();
          final List<dynamic> textList =
              (answer.containsKey("m.text") ? answer["m.text"] : []);
          if (textList.isNotEmpty && textList[0].containsKey("body")) {
            final text = answer["m.text"][0]["body"];
            final votes = _getOptionVotes(id, responses);
            options.add(PollOption(id: id, title: Text(text), votes: votes));
          }
        }
      }
    }

    return options;
  }

  Future<List<Event>> _getResponses() async {
    return await event.allResponses(timeline);
  }

  @override
  Widget build(BuildContext context) {
    if (event.type == EventTypes.PollStart) {
      _readPoll();

      if (_isValidPoll()) {
        //List<Event> responses =
        return FutureBuilder(
          future: _getResponses(),
          builder: (BuildContext ctx, AsyncSnapshot<List<Event>> snapshot) {
            if (snapshot.hasData) {
              final Event? endEvent = event.getPollEndEvent(timeline);
              final List<PollOption> options =
                  _makePollOptionsList(snapshot.data!);
              final userVotedOptionId = _getVoteId(snapshot.data!);

              return Container(
                color: Theme.of(context).colorScheme.primary,
                child: FlutterPolls(
                  pollId: event.eventId,
                  pollEnded: (endEvent != null),
                  hasVoted: (userVotedOptionId != null),
                  userVotedOptionId: userVotedOptionId,
                  userToVote: event.room.client.userID,
                  onVoted: (PollOption pollOption, int newTotalVotes) async {
                    if (onVoted != null) {
                      onVoted!(event, pollOption.id);
                    }

                    /// If HTTP status is success, return true else false
                    return true;
                  },
                  votedAnimationDuration: 0,
                  pollTitle: Align(
                    alignment: Alignment.center,
                    child: Column(
                      children: [
                        if (endEvent != null)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 5),
                            child: Text(
                              L10n.of(context)!.pollClosed,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        Text(
                          question!,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  pollOptionsBorderRadius: BorderRadius.circular(10.0),
                  pollOptionsBorder: Border.all(),
                  pollOptionsFillColor: Theme.of(context).colorScheme.primary,
                  pollOptionsSplashColor:
                      Theme.of(context).colorScheme.outline.withOpacity(0.2),
                  votedBackgroundColor:
                      Theme.of(context).colorScheme.outline.withOpacity(0.2),
                  votedProgressColor: const Color(0xff84D2F6),
                  leadingVotedProgessColor: const Color(0xff0496FF),
                  voteInProgressColor: const Color(0xffEEF0EB),
                  votedPercentageTextStyle: TextStyle(
                    inherit: false,
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                  votesTextStyle: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                  votedCheckmark: const Icon(
                    Icons.check_circle_outlined,
                    color: Colors.white,
                    size: 18,
                  ),
                  votesText: L10n.of(context)!.votes,
                  pollOptions: options,
                ),
              );
            } else {
              return const Center(
                child: CircularProgressIndicator.adaptive(
                  strokeWidth: 2,
                ),
              );
            }
          },
        );
      }
    }

    return Container();
  }
}
