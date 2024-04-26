import 'package:flutter/cupertino.dart';

import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:matrix/matrix.dart';
import 'package:scroll_to_index/scroll_to_index.dart';
import 'package:vrouter/vrouter.dart';

import 'chat_poll_creator_view.dart';

class ChatPollCreator extends StatefulWidget {
  const ChatPollCreator({Key? key}) : super(key: key);

  @override
  ChatPollCreatorController createState() => ChatPollCreatorController();
}

class ChatPollCreatorController extends State<ChatPollCreator> {
  String? get roomId => VRouter.of(context).pathParameters['roomid'];
  Room? room;

  final scrollController = AutoScrollController();
  bool showScrollToTopButton = false;
  static const fixedWidth = 360.0;
  static const minOptions = 2;

  final questionController = TextEditingController();
  final optionsController = [TextEditingController(), TextEditingController()];

  /* settings currently not used in UI */
  bool isLivePoll = false;
  bool showNames = false;
  bool allowFreeText = false;
  bool allowMultipleAnswers = false;

  String? questionError;
  String? optionsError;

  bool? saveSuccess;
  bool showLoading = false;

  void addOption() {
    setState(() {
      optionsController.add(TextEditingController());
    });
  }

  void removeOption(index) {
    setState(() {
      // at least one answer has to be there
      if (optionsController.length > minOptions) {
        optionsController[index].removeListener(_optionsListener);
        optionsController.removeAt(index);
      }
    });
  }

  void changeAllowFreeText(value) {
    setState(() {
      allowFreeText = value;
    });
  }

  void changeShowNames(value) {
    setState(() {
      showNames = value;
    });
  }

  void changeIsLivePoll(value) {
    setState(() {
      isLivePoll = value;
    });
  }

  void changeAllowMultipleAnswers(value) {
    setState(() {
      allowMultipleAnswers = value;
    });
  }

  void createPoll() async {
    saveSuccess = null;
    setState(() {
      showLoading = true;
    });

    if (questionController.text.isEmpty) {
      setState(() {
        questionError = L10n.of(context)?.questionMissing;
      });
    }

    final List<String> answers = [];
    for (final controller in optionsController) {
      if (controller.text.isNotEmpty) {
        answers.add(controller.text);
      }
    }

    if (answers.isEmpty) {
      setState(() {
        optionsError = L10n.of(context)?.answerMissing;
      });
    }

    int maxAnswers = 1;
    if (allowMultipleAnswers) {
      maxAnswers = answers.length;
    }

    if (!_hasError()) {
      final eventId = await room?.sendNewPoll(
        questionController.text,
        answers,
        isLivePoll,
        maxAnswers,
        allowFreeText,
        showNames,
      );

      if (eventId != null) {
        _clearView();
        scrollToTop();
        setState(() {
          saveSuccess = true;
          showLoading = false;
        });
      } else {
        setState(() {
          saveSuccess = false;
          showLoading = false;
        });
      }
    }
  }

  bool _hasError() {
    return (questionError != null && questionError!.isNotEmpty) ||
        (optionsError != null && optionsError!.isNotEmpty);
  }

  void _clearView() {
    questionError = null;
    optionsError = null;

    questionController.text = "";

    // if there are more than two options remove them
    for (var i = optionsController.length - 1; i > minOptions - 1; i--) {
      optionsController[i].removeListener(_optionsListener);
      optionsController.removeAt(i);
    }

    // if there is only one option, add one
    while (optionsController.length < minOptions) {
      optionsController.add(TextEditingController());
    }

    for (var i = 0; i < optionsController.length; i++) {
      optionsController[i].text = "";
    }

    isLivePoll = false;
    showNames = false;
    allowFreeText = false;
    allowMultipleAnswers = false;
    setState(() {});
  }

  void setRoom(room) {
    this.room = room;
  }

  @override
  void initState() {
    scrollController.addListener(_updateScrollController);
    questionController.addListener(_questionListener);
    optionsController.first.addListener(_optionsListener);
    super.initState();
  }

  void _questionListener() {
    if (questionController.text.isNotEmpty) {
      setState(() {
        questionError = null;
      });
    }
  }

  void _optionsListener() {
    if (optionsController.first.text.isNotEmpty) {
      setState(() {
        optionsError = null;
      });
    }
  }

  void _updateScrollController() {
    if (!scrollController.hasClients) return;

    if (scrollController.position.pixels > 0 &&
        showScrollToTopButton == false) {
      setState(() => showScrollToTopButton = true);
    } else if (scrollController.position.pixels == 0 &&
        showScrollToTopButton == true) {
      setState(() => showScrollToTopButton = false);
    }
  }

  void scrollToTop() {
    scrollController.jumpTo(0);
  }

  @override
  void dispose() {
    scrollController.removeListener(_updateScrollController);
    questionController.removeListener(_questionListener);
    optionsController.first.removeListener(_optionsListener);

    questionController.dispose();
    for (final controller in optionsController) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  void setState(fn) {
    if (mounted) {
      super.setState(fn);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: fixedWidth,
      child: ChatPollCreatorView(this),
    );
  }
}
