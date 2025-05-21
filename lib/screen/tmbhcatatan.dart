import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill_extensions/flutter_quill_extensions.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../api/connect.dart';
import '../main.dart';

class TambahCatatanPage extends StatefulWidget {
  final dynamic catatan;

  const TambahCatatanPage({Key? key, this.catatan}) : super(key: key);

  @override
  State<TambahCatatanPage> createState() => _TambahCatatanPageState();
}

class _TambahCatatanPageState extends State<TambahCatatanPage> {
  final TextEditingController _titleController = TextEditingController();
  late QuillController _controller;
  final FocusNode _editorFocusNode = FocusNode();
  final ScrollController _editorScrollController = ScrollController();

  @override
  void initState() {
    super.initState();

    _titleController.text = widget.catatan?.judul ?? '';
    final rawDeskripsi = widget.catatan?.deskripsi ?? '';
    Document document;

    try {
      document =
          rawDeskripsi.isNotEmpty
              ? Document.fromJson(jsonDecode(rawDeskripsi))
              : Document();
    } catch (_) {
      document = Document()..insert(0, rawDeskripsi);
    }

    _controller = QuillController(
      document: document,
      selection: const TextSelection.collapsed(offset: 0),
    );
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      final path = picked.path;
      final index = _controller.selection.baseOffset;

      _controller.document.insert(index, BlockEmbed.image(path));
      _controller.updateSelection(
        TextSelection.collapsed(offset: index + 1),
        ChangeSource.local,
      );

      setState(() {});
    }
  }

  Future<void> _saveNote() async {
    final title = _titleController.text.trim();

    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Judul catatan tidak boleh kosong')),
      );
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('user_id');

    if (userId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('User belum login')));
      return;
    }

    final deltaJson = jsonEncode(_controller.document.toDelta().toJson());

    final Map<String, dynamic> body = {
      'user_id': userId,
      'judul': title,
      'deskripsi': deltaJson,
      'tgl': DateTime.now().toIso8601String().substring(0, 10),
      'gambar': null,
    };

    try {
      final response = await http.post(
        Uri.parse('$ip/catatan'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final imagePaths = _extractImagePathsFromDocument(_controller.document);

        for (final imagePath in imagePaths) {
          if (!imagePath.startsWith('http')) {
            await _uploadImage(userId, imagePath);
          }
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Catatan "$title" berhasil disimpan')),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => HomeScreen()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menyimpan catatan: ${response.body}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Terjadi kesalahan: $e')));
    }
  }

  List<String> _extractImagePathsFromDocument(Document document) {
    final imagePaths = <String>[];
    final deltaOps = document.toDelta().toJson();

    for (final op in deltaOps) {
      if (op['insert'] is Map && op['insert']['image'] != null) {
        final path = op['insert']['image'];
        if (path != null && path is String) {
          imagePaths.add(path);
        }
      }
    }
    return imagePaths;
  }

  Future<void> _uploadImage(int userId, String imagePath) async {
    final uri = Uri.parse('$ip/upload_gambar');

    final request = http.MultipartRequest('POST', uri);
    request.fields['user_id'] = userId.toString();

    final multipartFile = await http.MultipartFile.fromPath(
      'gambar',
      imagePath,
    );
    request.files.add(multipartFile);

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode != 200) {
      throw Exception('Gagal upload gambar: ${response.body}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      backgroundColor: const Color(0xFFF0FEFF),
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: EdgeInsets.only(bottom: keyboardHeight),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 25,
                    vertical: 45,
                  ),
                  child: IntrinsicHeight(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            InkWell(
                              onTap:
                                  () => Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => HomeScreen(),
                                    ),
                                  ),
                              borderRadius: BorderRadius.circular(20),
                              child: const Icon(Icons.arrow_back, size: 25),
                            ),
                            InkWell(
                              borderRadius: BorderRadius.circular(20),
                              onTap: _saveNote,
                              child: const Text(
                                'Simpan',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: TextField(
                            controller: _titleController,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                            decoration: const InputDecoration(
                              hintText: 'Judul',
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black12,
                                  blurRadius: 6,
                                  offset: Offset(0, 3),
                                ),
                              ],
                            ),
                            child: QuillEditor(
                              controller: _controller,
                              focusNode: _editorFocusNode,
                              scrollController: _editorScrollController,
                              config: QuillEditorConfig(
                                placeholder: 'Tulis catatan di sini...',
                                embedBuilders: [
                                  ...FlutterQuillEmbeds.editorBuilders(
                                    imageEmbedConfig:
                                        QuillEditorImageEmbedConfig(
                                          imageProviderBuilder: (
                                            context,
                                            imageUrl,
                                          ) {
                                            if (imageUrl.startsWith(
                                              'assets/',
                                            )) {
                                              return AssetImage(imageUrl);
                                            } else if (imageUrl.startsWith(
                                              '/',
                                            )) {
                                              return FileImage(File(imageUrl));
                                            } else if (imageUrl.startsWith(
                                              'http',
                                            )) {
                                              return NetworkImage(imageUrl);
                                            }
                                            return null;
                                          },
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          height: 55,
                          margin: const EdgeInsets.only(top: 10),
                          padding: const EdgeInsets.symmetric(horizontal: 40),
                          decoration: BoxDecoration(
                            color: const Color(0xFF24527A),
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black26,
                                blurRadius: 10,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              IconButton(
                                tooltip: 'Bold',
                                icon: Icon(
                                  Icons.format_bold,
                                  color:
                                      _controller
                                              .getSelectionStyle()
                                              .attributes
                                              .containsKey('bold')
                                          ? Colors.white
                                          : Colors.white60,
                                ),
                                onPressed: () {
                                  _controller.formatSelection(
                                    _controller
                                            .getSelectionStyle()
                                            .attributes
                                            .containsKey('bold')
                                        ? Attribute.clone(Attribute.bold, null)
                                        : Attribute.bold,
                                  );
                                  setState(() {});
                                },
                              ),
                              IconButton(
                                tooltip: 'Italic',
                                icon: Icon(
                                  Icons.format_italic,
                                  color:
                                      _controller
                                              .getSelectionStyle()
                                              .attributes
                                              .containsKey('italic')
                                          ? Colors.white
                                          : Colors.white60,
                                ),
                                onPressed: () {
                                  _controller.formatSelection(
                                    _controller
                                            .getSelectionStyle()
                                            .attributes
                                            .containsKey('italic')
                                        ? Attribute.clone(
                                          Attribute.italic,
                                          null,
                                        )
                                        : Attribute.italic,
                                  );
                                  setState(() {});
                                },
                              ),
                              IconButton(
                                tooltip: 'Underline',
                                icon: Icon(
                                  Icons.format_underline,
                                  color:
                                      _controller
                                              .getSelectionStyle()
                                              .attributes
                                              .containsKey('underline')
                                          ? Colors.white
                                          : Colors.white60,
                                ),
                                onPressed: () {
                                  _controller.formatSelection(
                                    _controller
                                            .getSelectionStyle()
                                            .attributes
                                            .containsKey('underline')
                                        ? Attribute.clone(
                                          Attribute.underline,
                                          null,
                                        )
                                        : Attribute.underline,
                                  );
                                  setState(() {});
                                },
                              ),
                              IconButton(
                                tooltip: 'Insert Image',
                                icon: const Icon(
                                  Icons.image,
                                  color: Colors.white,
                                ),
                                onPressed: _pickImage,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
