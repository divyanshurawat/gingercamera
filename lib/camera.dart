import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:io';
import 'package:collection/collection.dart';
import 'package:flutter/rendering.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:photo_gallery/photo_gallery.dart';
import 'package:transparent_image/transparent_image.dart';
import 'package:take_picture_native/take_picture_native.dart';
import 'dart:io' as io;
import 'package:path_provider/path_provider.dart';
import 'package:external_path/external_path.dart';

class Camera extends StatefulWidget {
  const Camera({Key? key}) : super(key: key);

  @override
  State<Camera> createState() => _CameraState();
}

class _CameraState extends State<Camera> with WidgetsBindingObserver {
  List<Album>? _albums;
  bool _loading = false;
  final foldername = new TextEditingController();
  Directory? directory;
  List oldfile = [];
  List newfile = [];
  bool iskBActive = false;
  PictureDataModel? _pictureDataModel;
  List<String> oldList = [];
  List<String> newList = [];
  List selectImg = [];
  bool _isInForeground = true;
  @override
  void initState() {
    super.initState();
    _pictureDataModel = PictureDataModel();
    _pictureDataModel!.inputClickState.add([]);
    _loading = true;
    WidgetsBinding.instance!.addObserver(this);
    initAsync();

    _fetchOldList();
  }

  Future<File> moveFile(File sourceFile, String newPath) async {
    try {
      print('done');
      // prefer using rename as it is probably faster
      return await sourceFile.rename(newPath);
    } on FileSystemException catch (e) {
      print(e);
      // if rename fails, copy the source file and then delete it
      final newFile = await sourceFile.copy(newPath);
      await sourceFile.delete();
      return newFile;
    }
  }

  void _fetchOldList() async {
    var path = await ExternalPath.getExternalStoragePublicDirectory(
        ExternalPath.DIRECTORY_DCIM);
    print(path);

    setState(() {
      oldfile = Directory("$path/Camera")
          .listSync(); //use your folder name insted of resume.
    });
    oldfile.forEach((element) {
      oldList.add(element.toString().substring(6).replaceAll(" ", ""));
    });
  }

  void _fetchNewList() async {
    var path = await ExternalPath.getExternalStoragePublicDirectory(
        ExternalPath.DIRECTORY_DCIM);

    setState(() {
      newfile = Directory("$path/Camera").listSync();
    });

    newfile.forEach((element) {
      newList.add(element.toString().substring(6).replaceAll(" ", ""));
    });
    for (var element in newList) {
      if (!oldList.contains(element)) {
        if (kDebugMode) {
          moveFile(File(element.replaceAll("'", "")),
              "/storage/emulated/0/Download/");
          print(element.replaceAll("'", ""));
        }
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    _isInForeground = state == AppLifecycleState.resumed;

    if (_isInForeground) {
      _fetchNewList();
    } else {
      _fetchOldList();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance!.removeObserver(this);
    super.dispose();
  }

  _createFolder() async {
    final path = Directory("storage/emulated/0/DCIM/${foldername.text}");
    if ((await path.exists())) {
      // TODO:
      print("exist");
    } else {
      // TODO:
      print("not exist");
      path.create();
    }
  }

  Future<void> initAsync() async {
    if (await _promptPermissionSetting()) {
      List<Album> albums =
          await PhotoGallery.listAlbums(mediumType: MediumType.image);

      // File file = await PhotoGallery.getFile(mediumId: "1222830784");
      //print(file);
      setState(() {
        _albums = albums;
        _loading = false;
      });
    }
    setState(() {
      _loading = false;
    });
    // print(_albums);
  }

  Future<bool> _promptPermissionSetting() async {
    if (Platform.isIOS &&
            await Permission.storage.request().isGranted &&
            await Permission.photos.request().isGranted ||
        Platform.isAndroid && await Permission.storage.request().isGranted) {
      return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          TakePictureNative.openCamera;
        },
        child: const Icon(Icons.camera_alt_outlined),
      ),
      appBar: AppBar(
        backgroundColor: const Color(0xFFb01225),
        centerTitle: true,
        title: const Text("Ginger Camera"),
        actions: [
          IconButton(
              iconSize: 27, onPressed: () {}, icon: const Icon(Icons.share))
        ],
      ),
      backgroundColor: Colors.white,
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : Stack(
              children: [
                LayoutBuilder(
                  builder: (context, constraints) {
                    double gridWidth = (constraints.maxWidth - 20) / 3;
                    double gridHeight = gridWidth + 33;
                    double ratio = gridWidth / gridHeight;
                    return Container(
                      padding: const EdgeInsets.all(2),
                      child: GridView.count(
                        childAspectRatio: ratio,
                        crossAxisCount: 2,
                        crossAxisSpacing: 1.0,
                        children: <Widget>[
                          ...?_albums?.map(
                            (album) => GestureDetector(
                              onDoubleTap: () {},
                              onTap: () => Navigator.of(context).push(
                                  MaterialPageRoute(
                                      builder: (context) => AlbumPage(album))),
                              child: Column(
                                children: <Widget>[
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(5.0),
                                    child: Container(
                                      color: Colors.grey[300],
                                      height: gridWidth,
                                      width: gridWidth,
                                      child: FadeInImage(
                                        fit: BoxFit.contain,
                                        placeholder:
                                            MemoryImage(kTransparentImage),
                                        image: AlbumThumbnailProvider(
                                          albumId: album.id,
                                          mediumType: album.mediumType,
                                          highQuality: true,
                                        ),
                                      ),
                                    ),
                                  ),
                                  Container(
                                    alignment: Alignment.topLeft,
                                    padding: const EdgeInsets.only(left: 2.0),
                                    child: Text(
                                      album.name ?? "Unnamed Album",
                                      maxLines: 1,
                                      textAlign: TextAlign.start,
                                      style: const TextStyle(
                                        height: 1.2,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    alignment: Alignment.topLeft,
                                    padding: const EdgeInsets.only(left: 2.0),
                                    child: Text(
                                      album.count.toString(),
                                      textAlign: TextAlign.start,
                                      style: const TextStyle(
                                        height: 1.2,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: ElevatedButton(
                          style: ElevatedButton.styleFrom(),
                          onPressed: () {
                            setState(() {
                              iskBActive = true;
                            });
                            //  _createFolder();
                          },
                          child: Icon(Icons.add)),
                    ),
                  ],
                ),
                iskBActive
                    ? AlertDialog(
                        title: TextFormField(
                          onSaved: (v) {
                            setState(() {
                              //   iskBActive=false;
                            });
                          },
                          controller: foldername,
                        ),
                        content: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(),
                                  onPressed: () {
                                    if (foldername.text.length > 0) {
                                      _createFolder();
                                      setState(() {
                                        iskBActive = false;
                                      });
                                    }
                                  },
                                  child: const Text("  Save  ")),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(),
                                  onPressed: () {
                                    setState(() {
                                      iskBActive = false;
                                    });
                                    //  _createFolder();
                                  },
                                  child: Text("Cancel")),
                            ),
                          ],
                        ),
                      )
                    : Text(""),
              ],
            ),
    );
  }
}

class AlbumPage extends StatefulWidget {
  final Album album;

  AlbumPage(Album album) : album = album;

  @override
  State<StatefulWidget> createState() => AlbumPageState();
}

class AlbumPageState extends State<AlbumPage> {
  List<Medium>? _media;

  @override
  void initState() {
    super.initState();
    initAsync();
  }

  void initAsync() async {
    MediaPage mediaPage = await widget.album.listMedia();
    setState(() {
      _media = mediaPage.items;
    });
    print(_media!.map((e) => e));
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFFb01225),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text(widget.album.name ?? "Unnamed Album"),
        ),
        body: GridView.count(
          crossAxisCount: 3,
          mainAxisSpacing: 1.0,
          crossAxisSpacing: 1.0,
          children: <Widget>[
            ...?_media?.map(
              (medium) => GestureDetector(
                onTap: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => ViewerPage(medium))),
                child: Container(
                  color: Colors.grey[300],
                  child: FadeInImage(
                    fit: BoxFit.cover,
                    placeholder: MemoryImage(kTransparentImage),
                    image: ThumbnailProvider(
                      mediumId: medium.id,
                      mediumType: medium.mediumType,
                      highQuality: true,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ViewerPage extends StatelessWidget {
  final Medium medium;

  ViewerPage(Medium medium) : medium = medium;

  @override
  Widget build(BuildContext context) {
    DateTime? date = medium.creationDate ?? medium.modifiedDate;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFb01225),
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back_ios),
        ),
        title: date != null ? Text(date.toLocal().toString()) : null,
      ),
      body: Container(
        alignment: Alignment.center,
        child: FadeInImage(
          fit: BoxFit.cover,
          placeholder: MemoryImage(kTransparentImage),
          image: PhotoProvider(mediumId: medium.id),
        ),
      ),
    );
  }
}

class PictureDataModel {
  final StreamController<List<String>> _streamController =
      StreamController<List<String>>.broadcast();

  Sink<List<String>> get inputClickState => _streamController;

  Stream<List<String>> get outputResult =>
      _streamController.stream.map((data) => data);

  dispose() => _streamController.close();
}
