import 'package:audioplayers/audioplayers.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:chat_demo/common/enums/message_enum.dart';
import 'package:chat_demo/features/chat/widgets/video_player_item.dart';
import 'package:flutter/material.dart';

class DisplayTextImageGif extends StatelessWidget {
  const DisplayTextImageGif({
    super.key,
    required this.message,
    required this.type,
  });

  final String message;
  final MessageEnum type;

  @override
  Widget build(BuildContext context) {
    bool isPlaying = false;
    final AudioPlayer audioPlayer = AudioPlayer();

    return type == MessageEnum.text
        ? Text(
            message,
            style: const TextStyle(fontSize: 16),
          )
        : type == MessageEnum.image
            ? CachedNetworkImage(
                imageUrl: message,
              )
            : type == MessageEnum.video
                ? VideoPlayerItem(videoUrl: message)
                : type == MessageEnum.gif
                    ? CachedNetworkImage(
                        imageUrl: message,
                      )
                    : type == MessageEnum.audio
                        ? StatefulBuilder(
                            builder: (context, setState) {
                              return IconButton(
                                constraints:
                                    const BoxConstraints(minWidth: 100),
                                onPressed: () async {
                                  if (isPlaying) {
                                    await audioPlayer.pause();
                                    setState(() {
                                      isPlaying = false;
                                    });
                                  } else {
                                    await audioPlayer.play(UrlSource(message));
                                    setState(() {
                                      isPlaying = true;
                                    });
                                  }
                                },
                                icon: Icon(
                                  isPlaying
                                      ? Icons.pause_circle
                                      : Icons.play_circle,
                                ),
                              );
                            },
                          )
                        : Text(
                            message,
                            style: const TextStyle(fontSize: 16),
                          );
  }
}
