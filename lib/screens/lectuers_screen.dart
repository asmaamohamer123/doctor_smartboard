import 'dart:io';
import 'dart:typed_data';
import 'package:attendance/screens/assignmentpage.dart';
import 'package:attendance/screens/lecturepage.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class LecturesScreen extends StatefulWidget {
  const LecturesScreen({super.key, required this.title});
  final String title;

  @override
  State<LecturesScreen> createState() => _LecturesScreenState();
}

class _LecturesScreenState extends State<LecturesScreen> {
  int _selectedIndex = 0;

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      LecturePage(subjectName: widget.title),
      AssignmentPage(subjectName: widget.title),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> _pickAndUploadFile() async {
    FilePickerResult? result = await FilePicker.platform
        .pickFiles(type: FileType.custom, allowedExtensions: ['pdf']);

////////////////////////////////////////////////////////
         showLoadingDialog(context);
         ///////////////////////////////////////////////
          
    if (result != null) {
      String? filePath = result.files.single.path;
      String fileName = result.files.single.name;

      if (filePath != null) {
        Uint8List fileBytes = await File(filePath).readAsBytes();

        Reference storageRef =
            FirebaseStorage.instance.ref().child('uploads/$fileName');
        UploadTask uploadTask = storageRef.putData(fileBytes);

        await uploadTask.whenComplete(() async {
          String downloadURL = await storageRef.getDownloadURL();

          String subCollectionName =
              _selectedIndex == 0 ? 'lectures' : 'assignments';
          String subjectName = widget.title;

          await FirebaseFirestore.instance
              .collection('subjects')
              .doc(subjectName)
              .collection(subCollectionName)
              .add({
            'file_name': fileName,
            'file_url': downloadURL,
            'created_at': Timestamp.now(),
          });
     
///////////////////////////////////
                                   {
                                        Navigator.pop(
                                            context); 
                                      }

////////////////////////////////


           

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('تم رفع الملف بنجاح')),
            );
          }
        });
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('فشل في تحديد الملف')),
          );
        }
      }
    }
    

  }
   void showLoadingDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const Dialog(
          backgroundColor: Colors.transparent,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 10),
              Text(" ....جاري التحميل", style: TextStyle(color: Colors.white)),
            ],
          ),
        );
      },
    );
  } 


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        centerTitle: true,
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(
              Icons.school,
              color: Colors.white,
            ),
            label: 'المحاضرات',
          ),
          BottomNavigationBarItem(
            icon: Icon(
              Icons.assignment,
              color: Colors.white,
            ),
            label: 'التاسكات',
          ),
        ],
        selectedFontSize: 20,
        unselectedItemColor: Colors.black,
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.white,
        onTap: _onItemTapped,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _pickAndUploadFile,

        label: Text(_selectedIndex == 0 ? 'إضافة محاضرة' : 'إضافة تاسك'),
        icon: const Icon(Icons.add),
        
      ),
    );
  }
}

class PDFViewerPage extends StatelessWidget {
  final File file;
  final String title;

  const PDFViewerPage({super.key, required this.file, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: PDFView(
        filePath: file.path,
      ),
    );
  }
}
