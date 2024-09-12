import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:future_loading_dialog/future_loading_dialog.dart';
import 'package:matrix/encryption.dart';
import 'package:matrix/encryption/utils/bootstrap.dart';
import 'package:matrix/matrix.dart';

import 'package:fluffychat/config/themes.dart';
import 'package:fluffychat/utils/platform_infos.dart';
import 'package:fluffychat/widgets/adaptive_flat_button.dart';
import '../key_verification/key_verification_dialog.dart';

class BootstrapDialog extends StatefulWidget {
  final bool wipe;
  final Client client;
  const BootstrapDialog({
    Key? key,
    this.wipe = false,
    required this.client,
  }) : super(key: key);

  Future<bool?> show(BuildContext context) => PlatformInfos.isCupertinoStyle
      ? showCupertinoDialog(
          context: context,
          builder: (context) => this,
          barrierDismissible: true,
          useRootNavigator: false,
        )
      : showDialog(
          context: context,
          builder: (context) => this,
          barrierDismissible: true,
          useRootNavigator: false,
        );

  @override
  BootstrapDialogState createState() => BootstrapDialogState();
}

// After initialization, BootstrapState is either
// askWipeSsss: in case secrets were found or
// askNewSsss: in case no secrets were found
class BootstrapDialogState extends State<BootstrapDialog> {
  final TextEditingController _backupAnswerTextEditingController =
      TextEditingController();
  final TextEditingController _recoveryKeyTextEditingController =
      TextEditingController();

  Bootstrap? bootstrap;

  String? _recoveryKeyInputError;

  bool _recoveryKeyInputLoading = false;

  String? titleText;

  // is set in BootstrapState.openExistingSsss:
  bool _recoveryKeyStored = false;
  bool _recoveryKeyCopied = false;

  bool? _storeInSecureStorage = false;

  bool? _wipe;

  // contains the choosen question
  String? dropdownValue;

  bool keepOldKeys = false;

  bool analyzedAccountData = false;

  String? answerShort;

  String get _secureStorageKey =>
      'ssss_recovery_key_${bootstrap?.client.userID}';

  bool get _supportsSecureStorage =>
      PlatformInfos.isMobile ||
      PlatformInfos.isDesktop; // || PlatformInfos.isWeb;

  String _getSecureStorageLocalizedName() {
    if (PlatformInfos.isAndroid) {
      return L10n.of(context)!.storeInAndroidKeystore;
    }
    if (PlatformInfos.isIOS || PlatformInfos.isMacOS) {
      return L10n.of(context)!.storeInAppleKeyChain;
    }
    return L10n.of(context)!.storeSecurlyOnThisDevice;
  }

  // Those question can be used during setup of Online Backup
  Map<String, dynamic> _backupQuestions = {};

  // Those question can no longer be used during setup of Online Bakup
  // If they are in use, we will still be able to show them to the user
  // but in case the online Backup is reset, only _backupQuestions are possible
  Map<String, dynamic> _historicalQuestions = {};

  Future<void> completeSelfSign(key) async {
    await bootstrap?.client.encryption!.crossSigning.selfSign(
      keyOrPassphrase: key,
    );
    Logs().d('Success: selfsigned');
  }

  // TODO race condition
  Future<void> updateAccountdataQuestion() async {
    if (dropdownValue != null) {
      await bootstrap?.client.setBackupQuestion(dropdownValue!);
    }
  }

  // Creates a new SSSS secret, setup ignoring older secrets
  Future<void> createNewSsssSecret(String passphrase) async {
    await bootstrap?.newSsss(passphrase);
    if (bootstrap?.state == BootstrapState.askWipeCrossSigning) {
      await bootstrap?.wipeCrossSigning(true);
    }
    await bootstrap?.askSetupCrossSigning(
      setupMasterKey: true,
      setupSelfSigningKey: true,
      setupUserSigningKey: true,
    );
    if (bootstrap?.state == BootstrapState.askWipeOnlineKeyBackup) {
      bootstrap?.wipeOnlineKeyBackup(true);
    }
    await bootstrap?.askSetupOnlineKeyBackup(true);
  }

  // Creates a new SSSS secret, not ignoring older secrets
  Future<void> createNewSsssSecretKeepOldSsssKeys(String passphrase) async {
    await bootstrap?.newSsss(passphrase);
    await bootstrap?.wipeCrossSigning(false);
    if (bootstrap?.encryption.keyManager.enabled ?? false) {
      bootstrap?.wipeOnlineKeyBackup(false);
    }
  }

  bool isEncryptionEnabled() {
    return (bootstrap?.client.encryption?.keyManager.enabled == true &&
        //    await bootstrap?.client.encryption?.keyManager.isCached() == true &&
        //    await bootstrap?.client.encryption?.crossSigning.isCached() == true &&
        !(bootstrap?.client.isUnknownSession ?? true));
  }

  // Ask the user to choose a question
  Widget renderChooseAndAnswerBackupQuestion() {
    dropdownValue ??= 'q1';
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: Navigator.of(context).pop,
        ),
        title: Text(L10n.of(context)!.chooseSecQuestion),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints:
              const BoxConstraints(maxWidth: FluffyThemes.columnWidth * 1.5),
          child: ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 8.0),
                trailing: CircleAvatar(
                  backgroundColor: Colors.transparent,
                  child: Icon(
                    Icons.info_outlined,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                subtitle: Text(
                  L10n.of(context)!.chooseQuestion,
                ),
              ),
              if (dropdownValue == 'q5')
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8.0),
                  trailing: Icon(
                    Icons.info_outlined,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  subtitle: Text(
                    L10n.of(context)!.doNotUseBildungsportalPwd,
                  ),
                ),
              //TODO kann der recovery key erkannt werden, wenn man ihn eingegeben hat (chatbackup ist aktiviert), ohne ihn dann nochmal eingeben zu müssen?
              // zB wenn ein user den vor nem halben jahr eingab, aber nun nicht mehr weiß
              DropdownButton<String>(
                value: _backupQuestions[dropdownValue],
                isExpanded: true,
                icon: const Icon(Icons.keyboard_arrow_down),
                items: _backupQuestions.keys.map((String key) {
                  return DropdownMenuItem<String>(
                    value: _backupQuestions[key],
                    child: Text(_backupQuestions[key]!),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    final v = _backupQuestions.keys.firstWhere(
                      (key) => _backupQuestions[key] == newValue,
                    );
                    dropdownValue = v;
                  });
                },
              ),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 8.0),
                trailing: Icon(
                  Icons.info_outlined,
                  color: Theme.of(context).colorScheme.primary,
                ),
                subtitle: Text(L10n.of(context)!.hintLongPwd),
              ),
              TextField(
                minLines: 1,
                maxLines: 2,
                autocorrect: false,
                readOnly: _recoveryKeyInputLoading,
                autofillHints:
                    _recoveryKeyInputLoading ? null : [AutofillHints.password],
                controller: _backupAnswerTextEditingController,
                style: const TextStyle(fontFamily: 'RobotoMono'),
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.all(16),
                  hintStyle: TextStyle(
                    fontFamily:
                        Theme.of(context).textTheme.bodyLarge?.fontFamily,
                  ),
                  hintText: _backupQuestions[dropdownValue],
                  errorText: _recoveryKeyInputError,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  backgroundColor: Theme.of(context).primaryColor,
                ),
                icon: _recoveryKeyInputLoading
                    ? const CircularProgressIndicator.adaptive()
                    : const Icon(Icons.lock_open_outlined),
                label: Text(L10n.of(context)!.setAnswer),
                /*
                  onPressed: _recoveryKeyInputLoading
                      ? null
                      : () async {
                      */
                onPressed: () async {
                  setState(() {
                    _recoveryKeyInputError = null;
                    _recoveryKeyInputLoading = true;
                  });
                  try {
                    final key = _backupAnswerTextEditingController.text;
                    if (keepOldKeys) {
                      await createNewSsssSecretKeepOldSsssKeys(key);
                    } else {
                      await createNewSsssSecret(key);
                    }
                    _recoveryKeyStored = true;
                    await updateAccountdataQuestion();
                  } catch (e, s) {
                    Logs().w('Unable to setup backup question', e, s);
                    setState(
                      () => _recoveryKeyInputError =
                          L10n.of(context)!.oopsSomethingWentWrong,
                    );
                  } finally {
                    _initializing = false;
                    setState(
                      () => _recoveryKeyInputLoading = false,
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Ask the user for the answer to the backup question
  Widget renderBackupAnswer(answerShort) {
    if (_backupQuestions[answerShort] == null) {
      //if (_historicalQuestions[answerShort] == null) {
      //  Logs().w(
      //    'question was not found $answerShort',
      //  ); // TODO store answer tetx in account data too
      //} else {
      //  // TODO
      //  // we should rather set the short answer value here, but we need to access the question text later
      //  // dropdownValue = _historicalQuestions[answerShort];
      //}
    } else {
      dropdownValue = answerShort;
    }
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: Navigator.of(context).pop,
        ),
        title: Text(L10n.of(context)!.answerSecQuestion),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: FluffyThemes.columnWidth * 1.5,
          ),
          child: ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              _backupQuestions[dropdownValue] != null
                  ? Row(
                      children: [
                        Flexible(
                          child: Text(
                            _backupQuestions[dropdownValue],
                          ),
                        ),
                      ],
                    )
                  : Row(
                      children: [
                        const Expanded(child: Divider()),
                        Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Text(L10n.of(context)!.answerGivenQuest),
                        ),
                        const Expanded(child: Divider()),
                      ],
                    ),
              TextField(
                minLines: 1,
                maxLines: 2,
                autocorrect: false,
                readOnly: _recoveryKeyInputLoading,
                autofillHints:
                    _recoveryKeyInputLoading ? null : [AutofillHints.password],
                controller: _backupAnswerTextEditingController,
                style: const TextStyle(fontFamily: 'RobotoMono'),
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.all(16),
                  hintStyle: TextStyle(
                    fontFamily:
                        Theme.of(context).textTheme.bodyLarge?.fontFamily,
                  ),
                  hintText: _backupQuestions[dropdownValue],
                  errorText: _recoveryKeyInputError,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  backgroundColor: Theme.of(context).primaryColor,
                ),
                icon: _recoveryKeyInputLoading
                    ? const CircularProgressIndicator.adaptive()
                    : const Icon(Icons.lock_open_outlined),
                label: Text(L10n.of(context)!.unlockOldMessages),
                onPressed: _recoveryKeyInputLoading
                    ? null
                    : () async {
                        setState(() {
                          _recoveryKeyInputError = null;
                          _recoveryKeyInputLoading = true;
                        });
                        try {
                          final key = _backupAnswerTextEditingController.text;
                          await bootstrap?.newSsssKey!.unlock(
                            passphrase: key,
                          );
                          Logs().v('Unlocked newSsssKey');
                          await bootstrap?.openExistingSsss();

                          if (bootstrap?.encryption.crossSigning.enabled ??
                              false) {
                            Logs().v(
                              'Cross signing is already enabled. Try to self-sign',
                            );
                            try {
                              await bootstrap?.client.encryption!.crossSigning
                                  .selfSign(passphrase: key);
                              Logs().d('Successfully selfsigned');
                            } catch (e, s) {
                              Logs().e(
                                'Unable to self sign with recovery key after successfully open existing SSSS',
                                e,
                                s,
                              );
                            }
                          }
                        } catch (e, s) {
                          Logs().w('Unable to unlock SSSS', e, s);
                          setState(
                            () => _recoveryKeyInputError =
                                L10n.of(context)!.oopsSomethingWentWrong,
                          );
                        } finally {
                          _initializing = false;
                          setState(
                            () => _recoveryKeyInputLoading = false,
                          );
                        }
                      },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Expanded(child: Divider()),
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Text(L10n.of(context)!.or),
                  ),
                  const Expanded(child: Divider()),
                ],
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                icon: const Icon(Icons.cast_connected_outlined),
                label: Text(L10n.of(context)!.transferFromAnotherDevice),
                onPressed: _recoveryKeyInputLoading
                    ? null
                    : () async {
                        final req = await showFutureLoadingDialog(
                          context: context,
                          future: () => widget
                              .client.userDeviceKeys[widget.client.userID!]!
                              .startVerification(),
                        );
                        if (req.error != null) {
                          _initializing = false;
                          return;
                        }
                        await KeyVerificationDialog(
                          request: req.result!,
                        ).show(context);
                        _initializing = false;
                        Navigator.of(context, rootNavigator: false).pop();
                      },
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.red,
                ),
                icon: const Icon(Icons.delete_outlined),
                label: Text(L10n.of(context)!.recoveryKeyLost),
                onPressed: _recoveryKeyInputLoading
                    ? null
                    : () async {
                        if (OkCancelResult.ok ==
                            await showOkCancelAlertDialog(
                              useRootNavigator: false,
                              context: context,
                              title: L10n.of(context)!.recoveryKeyLost,
                              message: L10n.of(context)!.wipeChatBackup,
                              okLabel: L10n.of(context)!.ok,
                              cancelLabel: L10n.of(context)!.cancel,
                              isDestructiveAction: true,
                            )) {
                          setState(() => _createBootstrap(true));
                        }
                      },
              )
            ],
          ),
        ),
      ),
    );
  }

  // createNew indicates if a new SSSS key should be generated
  Future<void> setBackupAnswer([createNew = false]) async {
    Logs().v('setBackupAnswer, createNew is $createNew');
    try {
      final key = _backupAnswerTextEditingController.text;
      if (createNew == true) {
        await bootstrap?.newSsss(key);
        await bootstrap?.newSsssKey!.unlock(
          // instead of passing passphrase:
          // this enables the user to enter a (previous) recovery key
          keyOrPassphrase: key,
        );
        Logs().v('Unlocked newSsssKey');
      }
      // BootstrapState.askSetupCrossSigning is set at the end of newSsss
      if (!bootstrap!.client.encryption!.crossSigning.enabled ||
          bootstrap!.state == BootstrapState.askSetupCrossSigning) {
        // need to setup crossSigning for the first time
        await bootstrap?.askSetupCrossSigning(
          setupMasterKey: true,
          setupSelfSigningKey: true,
          setupUserSigningKey: true,
        );
        Logs().v('setup CrossSigning');
      }
      await completeSelfSign(key);
      Logs().v('completed self-sign');

      // store the used question in account_data
      await updateAccountdataQuestion();
      Logs().v('update account data');

      // ensure the key is unlocked
      await bootstrap?.newSsssKey!.unlock(
        keyOrPassphrase: key,
      );
      Logs().v('unlocked');
      await openExistingSsss();
      Logs().v('openExistingSsss');

      //await askSetupOnlineKeyBackup();
    } catch (e, s) {
      Logs().w('Unable to unlock SSSS', e, s);
      setState(
        () => _recoveryKeyInputError = L10n.of(context)!.oopsSomethingWentWrong,
      );
    } finally {
      setState(() {
        // TODO refactor, in the past this meant that the key was stored locally after it was set up
        _recoveryKeyStored = true;
        _recoveryKeyInputLoading = false;
      });
    }
  }

  Future<void> openExistingSsss() async {
    bootstrap?.state = BootstrapState.openExistingSsss;
    await bootstrap?.openExistingSsss();
  }

  /*
  Future<void> askSetupOnlineKeyBackup() async {
    bootstrap?.state = BootstrapState.askSetupOnlineKeyBackup;
    await bootstrap?.askSetupOnlineKeyBackup(true);
  }*/

  @override
  void initState() {
    _createBootstrap(widget.wipe);
    super.initState();
  }

  bool _initializing = false;

  void _createBootstrap(bool wipe) async {
    _initializing = true;
    _wipe = wipe;
    titleText = null;
    _recoveryKeyStored = false;
    _backupQuestions = await widget.client.getAvailBackupQuestions();
    // TODO old questions are ignored at the moment
    _historicalQuestions = _backupQuestions['disabled'];
    // this is done so that the dropdown menu only contains questions
    _backupQuestions.remove('disabled');
    bootstrap =
        widget.client.encryption!.bootstrap(onUpdate: (_) => setState(() {}));

    answerShort = widget.client.getBackupQuestion()?.startsWith('q') ?? false
        ? widget.client.getBackupQuestion()
        : null;
    // TODO remove
    final key = await const FlutterSecureStorage().read(key: _secureStorageKey);
    if (key == null) return;
    _backupAnswerTextEditingController.text = key;
  }

  Widget renderRequestRecoveryKey() {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: Navigator.of(context).pop,
        ),
        title: Text(
          L10n.of(context)!.enterRecoveryKey,
          textAlign: TextAlign.left,
          softWrap: true,
          overflow: TextOverflow.visible,
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: FluffyThemes.columnWidth * 1.5,
          ),
          child: ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 8.0),
                trailing: Icon(
                  Icons.info_outlined,
                  color: Theme.of(context).colorScheme.primary,
                ),
                subtitle: Text(
                  L10n.of(context)!.recoverOrVerify,
                ),
              ),
              const Divider(height: 32),
              TextField(
                minLines: 1,
                maxLines: 2,
                autocorrect: false,
                readOnly: _recoveryKeyInputLoading,
                autofillHints:
                    _recoveryKeyInputLoading ? null : [AutofillHints.password],
                controller: _recoveryKeyTextEditingController,
                style: const TextStyle(fontFamily: 'RobotoMono'),
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.all(16),
                  hintStyle: TextStyle(
                    fontFamily:
                        Theme.of(context).textTheme.bodyLarge?.fontFamily,
                  ),
                  hintText: L10n.of(context)!.currentRecoveryKey,
                  errorText: _recoveryKeyInputError,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  backgroundColor: Theme.of(context).primaryColor,
                ),
                icon: _recoveryKeyInputLoading
                    ? const CircularProgressIndicator.adaptive()
                    : const Icon(Icons.lock_open_outlined),
                label: Text(L10n.of(context)!.unlockOldMessages),
                onPressed: _recoveryKeyInputLoading
                    ? null
                    : () async {
                        //setState(() {
                        //  _recoveryKeyInputError = null;
                        //  _recoveryKeyInputLoading = true;
                        //});
                        bool lucky = false;
                        try {
                          Logs().v('try to unlock old secrets');
                          bootstrap?.state = BootstrapState.askUseExistingSsss;
                          // this should import oldSsssKeys
                          bootstrap?.useExistingSsss(false);

                          try {
                            if (bootstrap?.oldSsssKeys is Map) {
                              for (final entry
                                  in bootstrap!.oldSsssKeys!.entries) {
                                final key = entry.value;
                                final keyId = entry.key;
                                await bootstrap?.oldSsssKeys![keyId]?.unlock(
                                  keyOrPassphrase:
                                      _recoveryKeyTextEditingController.text,
                                );
                                if (key.isUnlocked) {
                                  lucky = true;
                                  keepOldKeys = true;
                                }
                              }
                            }
                            Logs().v('Successful unlocked old secrets');
                          } catch (_) {
                            Logs().w('Error during unlock_ : $_');
                          }
                        } catch (_) {
                          Logs().w('Error during unlock: $_');
                        }
                        if (lucky) {
                          bootstrap?.unlockedSsss();
                        } else {
                          Logs().v('Recovery Key was wrong');
                          // reset state so that the recovery key is asked again
                          bootstrap?.state = BootstrapState.askWipeSsss;
                          await showOkCancelAlertDialog(
                            useRootNavigator: false,
                            context: context,
                            title: L10n.of(context)!.errorWrongRecoveryKey,
                            message:
                                L10n.of(context)!.errorWrongRecoveryKeyLong,
                            okLabel: L10n.of(context)!.ok,
                            cancelLabel: L10n.of(context)!.cancel,
                          );
                          //return AlertDialog(
                          //  title:
                          //  Text('Wiederherstellungsschlüssel falsch. Versuche es erneut oder klicke auf Schlüssel löschen. Danach kannst Du deine alten Chats nicht mehr lesen.'),
                          //  content: PlatformInfos.isCupertinoStyle
                          //    ? const CupertinoActivityIndicator()
                          //    : const LinearProgressIndicator(),
                          //  actions: <AdaptiveFlatButton>[],
                          //);
                          // TODO: entweder ist an der stelle der/ein alter key unlocked, oder nicht. falls nicht verifiziert wurde und nichts unlocked wurde, sollte man an der stelle wipen bzw nochmal starten mit wipe=true
                        }
                        // await setBackupAnswer(false);
                      },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Expanded(child: Divider()),
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Text(L10n.of(context)!.or),
                  ),
                  const Expanded(child: Divider()),
                ],
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                icon: const Icon(Icons.cast_connected_outlined),
                label: Text(L10n.of(context)!.transferFromAnotherDevice),
                onPressed: _recoveryKeyInputLoading
                    ? null
                    : () async {
                        final req = await showFutureLoadingDialog(
                          context: context,
                          future: () => widget
                              .client.userDeviceKeys[widget.client.userID!]!
                              .startVerification(),
                        );
                        if (req.error != null) {
                          _initializing = false;
                          return;
                        }
                        await KeyVerificationDialog(
                          request: req.result!,
                        ).show(context);
                        _initializing = false;
                        Navigator.of(context, rootNavigator: false).pop();
                      },
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.red,
                ),
                icon: const Icon(Icons.delete_outlined),
                label: Text(L10n.of(context)!.recoveryKeyLost),
                onPressed: _recoveryKeyInputLoading
                    ? null
                    : () async {
                        if (OkCancelResult.ok ==
                            await showOkCancelAlertDialog(
                              useRootNavigator: false,
                              context: context,
                              title: L10n.of(context)!.recoveryKeyLost,
                              message: L10n.of(context)!.wipeChatBackup,
                              okLabel: L10n.of(context)!.ok,
                              cancelLabel: L10n.of(context)!.cancel,
                              isDestructiveAction: true,
                            )) {
                          setState(() => _createBootstrap(true));
                        }
                      },
              )
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    _wipe ??= widget.wipe;
    final buttons = <AdaptiveFlatButton>[];
    Widget body = PlatformInfos.isCupertinoStyle
        ? const CupertinoActivityIndicator()
        : const LinearProgressIndicator();
    titleText = L10n.of(context)!.loadingPleaseWait;

    // Setup security phrase
    // _recoveryKeyStored is false, so we did not reach BootstrapState.openExistingSsss yet
    // The security phrase/recovery key has not been entered yet
    if (bootstrap?.newSsssKey?.recoveryKey != null &&
        _recoveryKeyStored == false &&
        _recoveryKeyInputLoading == false) {
      // this is the recovery key for the new SSSS secret
      // final key = bootstrap?.newSsssKey!.recoveryKey;
      titleText = L10n.of(context)!.recoveryKey;
      return renderChooseAndAnswerBackupQuestion();
    } else {
      switch (bootstrap?.state) {
        case BootstrapState.loading:
        case null:
          break;
        case BootstrapState.askWipeSsss:
          if (answerShort != null || _wipe! || isEncryptionEnabled()) {
            WidgetsBinding.instance.addPostFrameCallback(
              (_) => bootstrap?.wipeSsss(_wipe!),
            );
          } else {
            return renderRequestRecoveryKey();
          }
          break;
        case BootstrapState.askBadSsss:
          WidgetsBinding.instance.addPostFrameCallback(
            (_) => bootstrap?.ignoreBadSecrets(true),
          );
          break;
        case BootstrapState.askUseExistingSsss:
          WidgetsBinding.instance.addPostFrameCallback(
            (_) => bootstrap?.useExistingSsss(!_wipe!),
          );
          break;
        case BootstrapState.askUnlockSsss:
          if (!_initializing) {
            WidgetsBinding.instance.addPostFrameCallback(
              (_) => bootstrap?.unlockedSsss(),
            );
          }
          break;
        case BootstrapState.askNewSsss:
          // Sicherheitsphrase wird neu eingerichtet;
          // entweder kein SSSS vorhanden oder _wipe = true (stimmt das noch??)
          // oder: migration von reovery key auf backupfrage, alten key mitnehmen?!
          //TODO login->forgot recovery key->"did not fnd prior secrets" und auswahl der backupfrage
          //     ist das korrekt? da bräuhte es ggfs. noch einen button "frage ändern?"
          if (_initializing || keepOldKeys) {
            if (_recoveryKeyInputLoading) {
              Logs().d('Setup still in progress...');
              break;
            }
            Logs().i(
              keepOldKeys
                  ? 'found some older secrets'
                  : 'did not find prior secrets',
            );
            return renderChooseAndAnswerBackupQuestion();
          }
          break;
        // Setup has been completed in a former session
        case BootstrapState.openExistingSsss:
          _recoveryKeyStored = true;
          answerShort = widget.client.getBackupQuestion();

          // SSSS mit Sicherheitsphrase bereits eingerichtet
          if (answerShort != null) {
            Logs().i('answer short (from account_data): $answerShort');
            return renderBackupAnswer(answerShort);
          } else {
            // Sicherheitsphrase noch nicht eingerichtet, aber alternatives SSSS bereits eingerichtet
            Logs().v(
                'a recovery was entered, but the security question is not configured yet');
            keepOldKeys = true;
            bootstrap?.state = BootstrapState.askNewSsss;
            return renderChooseAndAnswerBackupQuestion();
          }
        case BootstrapState.askWipeCrossSigning:
          WidgetsBinding.instance.addPostFrameCallback(
            (_) => bootstrap?.wipeCrossSigning(_wipe!),
          );
          break;
        case BootstrapState.askSetupCrossSigning:
          WidgetsBinding.instance.addPostFrameCallback(
            (_) => bootstrap?.askSetupCrossSigning(
              setupMasterKey: true,
              setupSelfSigningKey: true,
              setupUserSigningKey: true,
            ),
          );
          break;
        case BootstrapState.askWipeOnlineKeyBackup:
          WidgetsBinding.instance.addPostFrameCallback(
            (_) => bootstrap?.wipeOnlineKeyBackup(_wipe!),
          );

          break;
        case BootstrapState.askSetupOnlineKeyBackup:
          WidgetsBinding.instance.addPostFrameCallback(
            (_) => bootstrap?.askSetupOnlineKeyBackup(true),
          );
          break;
        case BootstrapState.error:
          titleText = L10n.of(context)!.oopsSomethingWentWrong;
          body = const Icon(Icons.error_outline, color: Colors.red, size: 40);
          buttons.add(
            AdaptiveFlatButton(
              label: L10n.of(context)!.close,
              onPressed: () =>
                  Navigator.of(context, rootNavigator: false).pop<bool>(false),
            ),
          );
          break;
        case BootstrapState.done:
          titleText = L10n.of(context)!.everythingReady;
          body = Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset('assets/backup.png', fit: BoxFit.contain),
              Text(L10n.of(context)!.yourChatBackupHasBeenSetUp),
            ],
          );
          buttons.add(
            AdaptiveFlatButton(
              label: L10n.of(context)!.close,
              onPressed: () =>
                  Navigator.of(context, rootNavigator: false).pop<bool>(false),
            ),
          );
          break;
      }
    }

    final title = Text(titleText!);
    if (PlatformInfos.isCupertinoStyle) {
      return CupertinoAlertDialog(
        title: title,
        content: body,
        actions: buttons,
      );
    }
    return AlertDialog(
      title: title,
      content: body,
      actions: buttons,
    );
  }
}
