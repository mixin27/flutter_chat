import 'dart:io';

import 'package:chat_demo/colors.dart';
import 'package:chat_demo/common/enums/message_enum.dart';
import 'package:chat_demo/common/utils/utils.dart';
import 'package:chat_demo/features/chat/controller/chat_controller.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:giphy_get/giphy_get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class BottomChatField extends ConsumerStatefulWidget {
  const BottomChatField({
    Key? key,
    required this.receiverUserId,
  }) : super(key: key);

  final String receiverUserId;

  @override
  ConsumerState<BottomChatField> createState() => _BottomChatFieldState();
}

class _BottomChatFieldState extends ConsumerState<BottomChatField> {
  final _messageController = TextEditingController();

  FlutterSoundRecorder? _soundRecorder;
  bool isRecorderInit = false;
  bool isRecordingAudio = false;

  bool isShowSendButton = false;
  bool isShowEmojiContainer = false;

  FocusNode focusNode = FocusNode();

  @override
  void initState() {
    _soundRecorder = FlutterSoundRecorder();
    openAudio();
    super.initState();
  }

  void openAudio() async {
    final status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      throw RecordingPermissionException('Mic permission is not allowed.');
    }

    await _soundRecorder!.openRecorder();
    isRecorderInit = true;
  }

  void sendTextMessage() async {
    if (isShowSendButton) {
      ref.read(chatControllerProvider).sendTextMessage(
            context,
            text: _messageController.text.trim(),
            receiverUserId: widget.receiverUserId,
          );

      setState(() {
        _messageController.text = "";
      });
    } else {
      if (!isRecorderInit) return;

      var tempDir = await getTemporaryDirectory();
      var path = '${tempDir.path}/flutter_sound.aac';

      if (isRecordingAudio) {
        await _soundRecorder!.stopRecorder();

        sendFileMessage(File(path), MessageEnum.audio);
      } else {
        await _soundRecorder!.startRecorder(toFile: path, codec: Codec.aacADTS);
      }

      setState(() {
        isRecordingAudio = !isRecordingAudio;
      });
    }
  }

  void sendFileMessage(
    File file,
    MessageEnum messageType,
  ) {
    ref.read(chatControllerProvider).sendFileMessage(
          context,
          file: file,
          receiverUserId: widget.receiverUserId,
          messageType: messageType,
        );
  }

  void sendGifMessage(
    String gifUrl,
    MessageEnum messageType,
  ) {
    ref.read(chatControllerProvider).sendGifMessage(
          context,
          gifUrl: gifUrl,
          receiverUserId: widget.receiverUserId,
        );
  }

  void selectImage() async {
    File? image = await pickImageFromGallery(context);

    if (image != null) {
      sendFileMessage(image, MessageEnum.image);
    }
  }

  void selectVideo() async {
    File? video = await pickVideoFromGallery(context);

    if (video != null) {
      sendFileMessage(video, MessageEnum.video);
    }
  }

  void selectGif() async {
    GiphyGif? gif = await pickGIF(context);

    if (gif != null && gif.url != null) {
      sendGifMessage(gif.url!, MessageEnum.gif);
    }
  }

  void hideKeyboard() {
    focusNode.unfocus();
  }

  void showKeyboard() {
    focusNode.requestFocus();
  }

  void hideEmojiContainer() {
    setState(() {
      isShowEmojiContainer = false;
    });
  }

  void showEmojiContainer() {
    setState(() {
      isShowEmojiContainer = true;
    });
  }

  void toggleEmojiKeyboardContainer() {
    if (isShowEmojiContainer) {
      showKeyboard();
      hideEmojiContainer();
    } else {
      hideKeyboard();
      showEmojiContainer();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _messageController,
                focusNode: focusNode,
                onChanged: (value) {
                  if (value.isNotEmpty) {
                    setState(() {
                      isShowSendButton = true;
                    });
                  } else {
                    setState(() {
                      isShowSendButton = false;
                    });
                  }
                },
                decoration: InputDecoration(
                  filled: true,
                  fillColor: mobileChatBoxColor,
                  prefixIcon: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: SizedBox(
                      width: 100,
                      child: Row(
                        children: [
                          IconButton(
                            onPressed: toggleEmojiKeyboardContainer,
                            icon: const Icon(
                              Icons.emoji_emotions,
                              color: Colors.grey,
                            ),
                          ),
                          IconButton(
                            onPressed: selectGif,
                            icon: const Icon(
                              Icons.gif,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  suffixIcon: SizedBox(
                    width: 100,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        IconButton(
                          onPressed: selectImage,
                          icon: const Icon(
                            Icons.camera_alt,
                            color: Colors.grey,
                          ),
                        ),
                        IconButton(
                          onPressed: selectVideo,
                          icon: const Icon(
                            Icons.attach_file,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  hintText: 'Type a message!',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20.0),
                    borderSide: const BorderSide(
                      width: 0,
                      style: BorderStyle.none,
                    ),
                  ),
                  contentPadding: const EdgeInsets.all(10),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 2, right: 2, bottom: 8),
              child: CircleAvatar(
                radius: 25,
                backgroundColor: tabColor,
                child: GestureDetector(
                  onTap: sendTextMessage,
                  child: Icon(
                    isShowSendButton
                        ? Icons.send
                        : isRecordingAudio
                            ? Icons.close
                            : Icons.mic,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
        isShowEmojiContainer
            ? SizedBox(
                height: 310,
                child: EmojiPicker(
                  onEmojiSelected: (category, emoji) {
                    _messageController.text =
                        _messageController.text + emoji.emoji;

                    if (!isShowSendButton) {
                      setState(() {
                        isShowSendButton = true;
                      });
                    }
                  },
                ),
              )
            : const SizedBox(),
      ],
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _soundRecorder!.closeRecorder();
    isRecorderInit = false;
    super.dispose();
  }
}
