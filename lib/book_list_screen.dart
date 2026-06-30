import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:path_provider_android/path_provider_android.dart';
import 'package:android_intent_plus/android_intent.dart';

const _navy = Color(0xFF2D3250);
const _coral = Color(0xFFFF7B5E);

class BookListScreen extends StatelessWidget {
  final String ageGroup;
  final String format;
  final Color themeColor;

  const BookListScreen({
    Key? key,
    required this.ageGroup,
    required this.format,
    required this.themeColor,
  }) : super(key: key);

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
        backgroundColor: const Color(0xFFFFF8F0),
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _navy),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ages $ageGroup',
              style: const TextStyle(
                fontFamily: 'Nunito',
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: _navy,
              ),
            ),
            Text(
              format,
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: _navy.withValues(alpha: 0.45),
              ),
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: themeColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              format == 'PDF' ? Icons.picture_as_pdf_rounded : Icons.description_rounded,
              size: 22,
              color: themeColor,
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
                  return const Center(
                    child: CircularProgressIndicator(color: _coral),
                  );
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('📭', style: TextStyle(fontSize: 48)),
                        const SizedBox(height: 12),
                        const Text(
                          'No books yet',
                          style: TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: _navy,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Ages $ageGroup · $format',
                          style: TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 14,
                            color: _navy.withValues(alpha: 0.4),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final books = snapshot.data!.docs;

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                  itemCount: books.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final bookData = books[index].data() as Map<String, dynamic>;
                    final bookTitle = bookData['title'] as String? ?? 'Unknown Book';
                    final assetPath = _assetPath(bookTitle);

                    return FutureBuilder<bool>(
                      future: _assetExists(assetPath),
                      builder: (context, snap) {
                        final isAvailable = snap.data ?? false;
                        return BookListItem(
                          bookName: bookTitle,
                          assetPath: assetPath,
                          isAvailable: isAvailable,
                          accentColor: themeColor,
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: () {
                  // Add book upload functionality
                },
                icon: const Icon(Icons.upload_rounded, size: 20),
                label: const Text('Upload Book'),
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
  final Color accentColor;

  const BookListItem({
    super.key,
    required this.bookName,
    required this.assetPath,
    required this.isAvailable,
    required this.accentColor,
  });

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
      final ext = widget.assetPath.substring(widget.assetPath.lastIndexOf('.'));
      final file = File('${dir.path}/${widget.bookName}$ext');
      await file.writeAsBytes(bytes.buffer.asUint8List());
      final filename = file.path.split('/').last;
      final intent = AndroidIntent(
        action: 'action_view',
        data: 'content://com.example.booksapp.fileprovider/cache/$filename',
        type: widget.assetPath.endsWith('.pdf') ? 'application/pdf' : 'application/msword',
        flags: [0x00000001],
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
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _navy.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 72,
            decoration: BoxDecoration(
              color: widget.accentColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                bottomLeft: Radius.circular(16),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: widget.accentColor.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Text('📖', style: TextStyle(fontSize: 22)),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              widget.bookName,
              style: const TextStyle(
                fontFamily: 'Nunito',
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: _navy,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 12),
          _buildButton(),
          const SizedBox(width: 14),
        ],
      ),
    );
  }

  Widget _buildButton() {
    if (_loading) {
      return const SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(strokeWidth: 2, color: _coral),
      );
    }

    return SizedBox(
      height: 36,
      child: ElevatedButton(
        onPressed: widget.isAvailable ? _openBook : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: widget.isAvailable ? _coral : const Color(0xFFE8E8E8),
          foregroundColor: widget.isAvailable ? Colors.white : _navy.withValues(alpha: 0.35),
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          textStyle: const TextStyle(
            fontFamily: 'Nunito',
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
        child: Text(widget.isAvailable ? 'OPEN' : 'GET'),
      ),
    );
  }
}
