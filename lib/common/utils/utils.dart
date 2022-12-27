import 'dart:io';

import 'package:chat_demo/environment.dart';
import 'package:flutter/material.dart';
import 'package:giphy_get/giphy_get.dart';
import 'package:image_picker/image_picker.dart';

void showSnackbar({required BuildContext context, required String content}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(content)),
  );
}

Future<File?> pickImageFromGallery(BuildContext context) async {
  File? image;
  try {
    final pickedImage = await ImagePicker().pickImage(
      source: ImageSource.gallery,
    );

    if (pickedImage != null) {
      image = File(pickedImage.path);
    }
  } catch (e) {
    showSnackbar(context: context, content: e.toString());
  }

  return image;
}

Future<File?> pickVideoFromGallery(BuildContext context) async {
  File? video;
  try {
    final pickedVideo = await ImagePicker().pickVideo(
      source: ImageSource.gallery,
    );

    if (pickedVideo != null) {
      video = File(pickedVideo.path);
    }
  } catch (e) {
    showSnackbar(context: context, content: e.toString());
  }

  return video;
}

Future<GiphyGif?> pickGIF(BuildContext context) async {
  GiphyGif? gif;
  try {
    gif = await GiphyGet.getGif(
      context: context,
      apiKey: Environment.giphyApiKey,
    );
  } catch (e) {
    showSnackbar(context: context, content: e.toString());
  }
  return gif;
}
