import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_pytorch/pigeon.dart';
import 'package:flutter_pytorch/flutter_pytorch.dart';
import 'package:tnau_f/NewScreen1.dart';
import 'package:tnau_f/NewScreen2.dart';
import 'package:tnau_f/NewScreen3.dart';
import 'package:http/http.dart' as http;
//import 'package:object_detection/LoaderState.dart'
import 'LoaderState.dart';
import 'NewScreen.dart';
import 'constant.dart';
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}
class _HomeScreenState extends State<HomeScreen> {
  late ModelObjectDetection _objectModel;
  String? _imagePrediction;
  String? status = '';
  static  var endpoint = Uri.parse("http://192.168.173./flutterr_test/upload.php");
  String? base64Image;
  List? _prediction;
  File? _image;
  ImagePicker _picker = ImagePicker();
  bool objectDetection = false;
  List<ResultObjectDetection?> objDetect = [];
  bool firststate = false;
  bool message = true;
  @override
  void initState() {
    super.initState();
    loadModel();
  }
  setStatus(String msg){
    setState(() {
      status = msg;
    });
  }
  void dioupload(File? image) async{
    final Dio dio=new Dio();
    try{
      var response = await dio.get("");
      print(response.statusCode);
    }
    on DioException catch (e){
      print(e);
    }
}
  Upload(file) async {
    print("enterted uploads");
    if(file == null){
      return ;
    }
    final Dio dio=new Dio();
    String filename = file.path.split('/').last;
    print(filename);
    print("Making http request");
    final String baseurl = "http://192.168.115.28/opp.php";
    FormData formdata = FormData.fromMap({
      "file": await MultipartFile.fromFile(
          file.path,
          filename: filename
      ),
    });
    Response response = await dio.post(baseurl,
      data: formdata,);
    if(response.statusCode == 200){
      print(response.toString());
      //print response from server
    }else{
      print("Error during connection to server.");
    }
  }

  Future loadModel() async {
    String pathObjectDetectionModel = "assets/models/yolov5s.torchscript";
    try {
      _objectModel = await FlutterPytorch.loadObjectDetectionModel(
          pathObjectDetectionModel, 3, 640, 640,
          labelPath: "assets/labels/labels.txt");
    } catch (e) {
      if (e is PlatformException) {
        print("only supported for android, Error is $e");
      } else {
        print("Error is $e");
      }
    }
  }

  void handleTimeout() {
    // callback function
    // Do some work.
    setState(() {
      firststate = true;
    });
  }

  Timer scheduleTimeout([int milliseconds = 10000]) =>
      Timer(Duration(milliseconds: milliseconds), handleTimeout);
  //running detections on image
  Future runObjectDetection() async {
    setState(() {
      firststate = false;
      message = false;
    });
    //pick an image

    final XFile? image = await _picker.pickImage(source: ImageSource.camera);
    Upload(image);
    if(image!= null){
      File? imgpath = File(image.path);
      base64Image = base64Encode(imgpath!.readAsBytesSync());
      //print(base64Image);
    }
    objDetect = await _objectModel.getImagePrediction(
        await File(image!.path).readAsBytes(),
        minimumScore: 0.1,
        IOUThershold: 0.3);
    objDetect.forEach((element) {
      str=element?.className;
      val=element?.classIndex;
      print({
        "score": element?.score,
        "className": element?.className,
        "class": element?.classIndex,
        "rect": {
          "left": element?.rect.left,
          "top": element?.rect.top,
          "width": element?.rect.width,
          "height": element?.rect.height,
          "right": element?.rect.right,
          "bottom": element?.rect.bottom,
        },
      });
    });
    scheduleTimeout(5 * 1000);
    setState(() {
      _image = File(image.path);
    });

   // dioupload(_image);
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Tomato Diseases Detector App")),
      backgroundColor: Colors.white,
      body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              //Image with Detections....

              !firststate
                  ? !message ? LoaderState() : Text("Select the Camera to Begin Detections")
                  : Expanded(
                child: Container(
                    height: 5,
                    width: 300,
                    child:
                    _objectModel.renderBoxesOnImage(_image!, objDetect)),
              ),

              // !firststate
              //     ? LoaderState()
              //     : Expanded(
              //         child: Container(
              //             height: 150,
              //             width: 300,
              //             child: objDetect.isEmpty
              //                 ? Text("hello")
              //                 : _objectModel.renderBoxesOnImage(
              //                     _image!, objDetect)),
              //       ),
              Center(
                child: Visibility(
                  visible: _imagePrediction != null,
                  child: Text("$_imagePrediction"),
                ),
              ),
              //Button to click pic
              ElevatedButton(
                onPressed: () {
                  runObjectDetection();
                },
                child: const Icon(Icons.camera),
              ),
              ElevatedButton(
                child: Text('Recommendation'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                ),

                // onPressed: _sendingMails,
                onPressed:() {
                  if (val == null) {
                    Navigator.push(
                        context, MaterialPageRoute(builder: (context) => NewScreen()));
                  }
                  if (val == 0) {
                    Navigator.push(
                        context, MaterialPageRoute(builder: (context) => NewScreen1()));
                  }
                  if (val == 1) {
                    Navigator.push(
                        context, MaterialPageRoute(builder: (context) => NewScreen2()));
                  }
                  if (val == 2) {
                    Navigator.push(
                        context, MaterialPageRoute(builder: (context) => NewScreen3()));
                  }
                },
              ),

            ],


          )),
    );
  }
}