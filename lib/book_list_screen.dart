import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:path_provider_android/path_provider_android.dart';
import 'package:android_intent_plus/android_intent.dart';

class BookListScreen extends StatelessWidget {
  final String ageGroup;
  final String format;
  final Color themeColor;

  const BookListScreen({Key? key, required this.ageGroup, required this.format, required this.themeColor}) : super(key: key);

  String _assetPath(String title) {
    final ext = format == 'PDF' ? 'pdf' : 'docx';
    final folder = format == 'PDF' ? 'PDF' : 'DOCS';
    return 'Books/$folder/$ageGroup/$title $ageGroup.$ext';
  }

  Future<bool> _assetExists(String assetPath) async {
    try {
      await rootBundle.load(assetPath);
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Ages $ageGroup'),
        backgroundColor: themeColor,
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Icon(
              format == 'PDF' ? Icons.picture_as_pdf : Icons.description,
              size: 35,
              color: format == 'PDF' ? const Color.fromARGB(255, 243, 7, 31) : const Color.fromARGB(255, 5, 135, 241),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('books')
                  .where('ageGroup', isEqualTo: ageGroup)
                  .where('format', isEqualTo: format)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Text(
                      'No books found for Ages $ageGroup ($format)',
                      style: const TextStyle(fontSize: 18),
                    ),
                  );
                }

                final books = snapshot.data!.docs;

                return ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: books.length,
                  itemBuilder: (context, index) {
                    var bookData = books[index].data() as Map<String, dynamic>;
                    String bookTitle = bookData['title'] ?? 'Unknown Book';
                    String assetPath = _assetPath(bookTitle);

                    return FutureBuilder<bool>(
                      future: _assetExists(assetPath),
                      builder: (context, snap) {
                        final isAvailable = snap.data ?? false;
                        return Column(
                          children: [
                            BookListItem(
                              bookName: bookTitle,
                              assetPath: assetPath,
                              isAvailable: isAvailable,
                            ),
                            const Divider(),
                          ],
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 30.0),
            child: ElevatedButton(
              onPressed: () {
                //Add book upload functionality
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: themeColor,
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
              ),
              child: const Text(
                'Upload Book',
                style: TextStyle(fontSize: 20, color: Colors.black),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class BookListItem extends StatefulWidget {
  final String bookName;
  final String assetPath;
  final bool isAvailable;

  const BookListItem({super.key, required this.bookName, required this.assetPath, required this.isAvailable});

  @override
  State<BookListItem> createState() => _BookListItemState();
}

class _BookListItemState extends State<BookListItem> {
  bool _loading = false;

  Future<void> _openBook() async {
    setState(() => _loading = true);
    try {
      final bytes = await rootBundle.load(widget.assetPath);
      final tempPath = await PathProviderAndroid().getTemporaryPath();
      final dir = Directory(tempPath!);
      final file = File('${dir.path}/${widget.bookName}${widget.assetPath.substring(widget.assetPath.lastIndexOf('.'))}');
      await file.writeAsBytes(bytes.buffer.asUint8List());
      final filename = file.path.split('/').last;
      final intent = AndroidIntent(
        action: 'action_view',
        data: 'content://com.example.booksapp.fileprovider/cache/$filename',
        type: widget.assetPath.endsWith('.pdf') ? 'application/pdf' : 'application/msword',
        flags: [0x00000001], // FLAG_GRANT_READ_URI_PERMISSION
      );
      await intent.launch();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open ${widget.bookName}')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Colors.redAccent, Colors.blueAccent],
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(Icons.ac_unit, color: Colors.white),
      ),
      title: Text(
        widget.bookName,
        style: const TextStyle(fontSize: 20),
      ),
      trailing: _buildTrailingButton(),
    );
  }

  Widget _buildTrailingButton() {
    if (_loading) {
      return const SizedBox(
        width: 30,
        height: 30,
        child: CircularProgressIndicator(),
      );
    }

    return ElevatedButton(
      onPressed: widget.isAvailable ? _openBook : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.grey[200],
        foregroundColor: widget.isAvailable ? Colors.blue : Colors.blue,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      child: Text(
        widget.isAvailable ? 'OPEN' : 'GET',
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
    );
  }
}
