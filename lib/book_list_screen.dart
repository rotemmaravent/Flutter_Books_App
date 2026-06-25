import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; 
 
class BookListScreen extends StatelessWidget {
  final String ageGroup;
  final String format;
  final Color themeColor;
 
  const BookListScreen({Key? key, required this.ageGroup, required this.format, required this.themeColor}) : super(key: key);
 
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
                  .where('ageGroup', isEqualTo: ageGroup) // sort by age group
                  .where('format', isEqualTo: format)     // filter by format
                  .snapshots(),
              builder: (context, snapshot) {
                // Loading state
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                // Error state
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Text(
                      'No books found for Ages $ageGroup ($format)',
                      style: const TextStyle(fontSize: 18),
                    ),
                  );
                }
 
                // Success state: data received successfully - building the list
                final books = snapshot.data!.docs;
 
                return ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: books.length,
                  itemBuilder: (context, index) {
                    var bookData = books[index].data() as Map<String, dynamic>;
                    String bookTitle = bookData['title'] ?? 'Unknown Book';
                    bool isDownloaded = index % 2 == 0;
 
                    return Column(
                      children: [
                        BookListItem(
                          bookName: bookTitle, 
                          isAlreadyDownloaded: isDownloaded,
                        ),
                        const Divider(),
                      ],
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
  final bool isAlreadyDownloaded;

  const BookListItem({Key? key, required this.bookName, required this.isAlreadyDownloaded}) : super(key: key);

  @override
  _BookListItemState createState() => _BookListItemState();
}

class _BookListItemState extends State<BookListItem> {
  // 0 = GET, 1 = Loading, 2 = OPEN
  late int buttonState; 

  @override
  void initState() {
    super.initState();
    buttonState = widget.isAlreadyDownloaded ? 2 : 0;
  }

  void _handleButtonPress() async {
    if (buttonState == 0) {
      setState(() {
        buttonState = 1; 
      });
      await Future.delayed(const Duration(seconds: 2));
      setState(() {
        buttonState = 2; 
      });
    } else if (buttonState == 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Opening ${widget.bookName}...')),
      );
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
    if (buttonState == 1) {
      return const SizedBox(
        width: 30,
        height: 30,
        child: CircularProgressIndicator(),
      );
    }

    bool isOpen = buttonState == 2;
    return ElevatedButton(
      onPressed: _handleButtonPress,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.grey[200],
        foregroundColor: isOpen ? Colors.blue : Colors.grey[800],
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      child: Text(
        isOpen ? 'OPEN' : 'GET',
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
    );
  }
}