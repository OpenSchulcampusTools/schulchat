import 'package:flutter/material.dart';

import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:vrouter/vrouter.dart';

import 'package:fluffychat/config/app_config.dart';
import 'package:fluffychat/pages/chat_poll/chat_poll_creator.dart';
import 'package:fluffychat/widgets/layouts/max_width_body.dart';
import 'package:fluffychat/widgets/matrix.dart';

class ChatPollCreatorView extends StatelessWidget {
  final ChatPollCreatorController controller;

  const ChatPollCreatorView(this.controller, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final room = Matrix.of(context).client.getRoomById(controller.roomId!);
    controller.setRoom(room);
    if (room == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(L10n.of(context)!.oopsSomethingWentWrong),
        ),
        body: Center(
          child: Text(L10n.of(context)!.youAreNoLongerParticipatingInThisChat),
        ),
      );
    } else {
      return Stack(
        children: [
          Scaffold(
            floatingActionButton: controller.showScrollToTopButton
                ? Padding(
                    padding: const EdgeInsets.only(bottom: 56.0),
                    child: FloatingActionButton(
                      heroTag: "searchBackToTop",
                      onPressed: controller.scrollToTop,
                      mini: true,
                      child: const Icon(Icons.arrow_upward_outlined),
                    ),
                  )
                : null,
            body: NestedScrollView(
              controller: controller.scrollController,
              headerSliverBuilder:
                  (BuildContext context, bool innerBoxIsScrolled) => <Widget>[
                SliverAppBar(
                  leading: IconButton(
                    icon: const Icon(Icons.close_outlined),
                    onPressed: () => VRouter.of(context)
                        .toSegments(['rooms', controller.roomId!]),
                  ),
                  elevation: Theme.of(context).appBarTheme.elevation,
                  floating: true,
                  pinned: true,
                  title: Text(L10n.of(context)!.newPoll),
                ),
              ],
              body: MaxWidthBody(
                withScrolling: true,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (controller.saveSuccess == true)
                      Padding(
                        padding: const EdgeInsets.only(top: 20, bottom: 8.0),
                        child: Text(
                          L10n.of(context)!.pollSaved,
                          style: const TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    if (controller.saveSuccess == false)
                      Padding(
                        padding: const EdgeInsets.only(top: 20, bottom: 8.0),
                        child: Text(
                          L10n.of(context)!.pollSaveError,
                          style: const TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.only(top: 20, bottom: 8.0),
                      child: TextField(
                        controller: controller.questionController,
                        decoration: InputDecoration(
                          border: const UnderlineInputBorder(),
                          label: Text(L10n.of(context)!.question),
                          errorText: controller.questionError,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 25.0, bottom: 0),
                      child: Text(
                        L10n.of(context)!.options,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    // controller.optionsController.forEach((key, value) ...[] {
                    for (var i = 1;
                        i < controller.optionsController.length + 1;
                        i++) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: TextField(
                          controller: controller.optionsController[i - 1],
                          decoration: InputDecoration(
                            errorText:
                                (i == 1) ? controller.optionsError : null,
                            border: const UnderlineInputBorder(),
                            label: Text("${L10n.of(context)!.option} $i"),
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.delete_outlined),
                              onPressed: () => controller.removeOption(i - 1),
                            ),
                          ),
                        ),
                      ),
                    ],
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Row(
                        children: [
                          IconButton(
                            tooltip: L10n.of(context)!.newOption,
                            icon: const Icon(Icons.add_circle_outline),
                            onPressed: () => controller.addOption(),
                          ),
                          Text(L10n.of(context)!.newOption)
                        ],
                      ),
                    ),
                    /* Padding(
                  padding: const EdgeInsets.only(top: 16, bottom: 8.0),
                  child: Column(
                    children: [
                      SwitchListTile.adaptive(
                        value: controller.allowMultipleAnswers,
                        title: Text(L10n.of(context)!.allowMultipleAnswers),
                        onChanged: (bool value) {
                          controller.changeAllowMultipleAnswers(value);
                        },
                      ),
                      SwitchListTile.adaptive(
                        value: controller.allowFreeText,
                        title: Text(L10n.of(context)!.allowFreeText),
                        onChanged: (bool value) {
                          controller.changeAllowFreeText(value);
                        },
                      ),
                      SwitchListTile.adaptive(
                        value: controller.showNames,
                        title: Text(L10n.of(context)!.showNames),
                        onChanged: (bool value) {
                          controller.changeShowNames(value);
                        },
                      ),
                      SwitchListTile.adaptive(
                        value: controller.isLivePoll,
                        title: Text(L10n.of(context)!.isLivePoll),
                        onChanged: (bool value) {
                          controller.changeIsLivePoll(value);
                        },
                      ),
                    ],
                  ),
                ),*/
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 24, bottom: 8.0),
                        child: ElevatedButton.icon(
                          onPressed: controller.createPoll,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppConfig.primaryColor,
                            elevation: 0,
                          ),
                          icon: const Icon(
                            Icons.poll_outlined,
                            color: Colors.white,
                          ),
                          label: Text(
                            L10n.of(context)!.newPoll,
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (controller.showLoading)
            const Opacity(
              opacity: 0.2,
              child: ModalBarrier(dismissible: false, color: Colors.black),
            ),
          if (controller.showLoading)
            const Center(
              child: CircularProgressIndicator.adaptive(
                strokeWidth: 2,
              ),
            ),
        ],
      );
    }
  }
}
