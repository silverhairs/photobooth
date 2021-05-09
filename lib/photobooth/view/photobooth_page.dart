import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:io_photobooth/photobooth/photobooth.dart';
import 'package:io_photobooth/stickers/stickers.dart';
import 'package:photobooth_ui/photobooth_ui.dart';

const _videoConstraints = VideoConstraints(
  width: 4096,
  height: 4096,
  facingMode: FacingMode(
    type: CameraType.user,
    constrain: Constrain.ideal,
  ),
);

class PhotoboothPage extends StatelessWidget {
  const PhotoboothPage({Key? key}) : super(key: key);

  static Route route() {
    return AppPageRoute(builder: (_) => const PhotoboothPage());
  }

  static const String name = 'PhotoboothPage';

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => PhotoboothBloc(),
      child: Navigator(
        onGenerateRoute: (_) => AppPageRoute(
          builder: (_) => const PhotoboothView(),
          settings: const RouteSettings(name: name),
        ),
      ),
    );
  }
}

class PhotoboothView extends StatefulWidget {
  const PhotoboothView({Key? key}) : super(key: key);

  @override
  _PhotoboothViewState createState() => _PhotoboothViewState();
}

class _PhotoboothViewState extends State<PhotoboothView> {
  final _controller = CameraController(
    options: const CameraOptions(
      audio: AudioConstraints(enabled: false),
      video: _videoConstraints,
    ),
  );

  bool get _isCameraAvailable =>
      _controller.value.status == CameraStatus.available;

  Future<void> _play() async {
    if (!_isCameraAvailable) return;
    return _controller.play();
  }

  Future<void> _stop() async {
    if (!_isCameraAvailable) return;
    return _controller.stop();
  }

  @override
  void initState() {
    super.initState();
    _initializeCameraController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _initializeCameraController() async {
    await _controller.initialize();
    await _play();
  }

  void _onSnapPressed({required double aspectRatio}) async {
    final picture = await _controller.takePicture();
    context
        .read<PhotoboothBloc>()
        .add(PhotoCaptured(aspectRatio: aspectRatio, image: picture));
    final stickersPage = StickersPage.route();
    await _stop();
    await Navigator.of(context).push(stickersPage);
    await _play();
  }

  @override
  Widget build(BuildContext context) {
    final orientation = MediaQuery.of(context).orientation;
    final aspectRatio = orientation == Orientation.portrait
        ? PhotoboothAspectRatio.portrait
        : PhotoboothAspectRatio.landscape;
    return Scaffold(
      body: _PhotoboothBackground(
        aspectRatio: aspectRatio,
        child: Camera(
          controller: _controller,
          placeholder: (_) => const PhotoboothPlaceholder(),
          preview: (context, preview) => PhotoboothPreview(
            preview: preview,
            onSnapPressed: () => _onSnapPressed(aspectRatio: aspectRatio),
          ),
          error: (context, error) => PhotoboothError(error: error),
        ),
      ),
    );
  }
}

class _PhotoboothBackground extends StatelessWidget {
  const _PhotoboothBackground({
    Key? key,
    required this.aspectRatio,
    required this.child,
  }) : super(key: key);

  final double aspectRatio;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const PhotoboothBackground(),
        Center(
          child: AspectRatio(
            aspectRatio: aspectRatio,
            child: Container(
              color: PhotoboothColors.black,
              child: child,
            ),
          ),
        ),
      ],
    );
  }
}
