import 'package:flutter/material.dart';
import 'package:sverd_barbershop/core/models/info_news.dart';
import 'package:sverd_barbershop/core/theme/colors.dart';

class InfoNewsDetailPage extends StatelessWidget {
  final InfoNews infoNews;

  const InfoNewsDetailPage({super.key, required this.infoNews});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        backgroundColor: kBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: kTextColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Info and News',
          style: TextStyle(
            color: kTextColor,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildImageHeader(),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Text(
                infoNews.title,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: kTextColor,
                  height: 1.3,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: _buildContent(),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildImageHeader() {
    return Container(
      margin: const EdgeInsets.all(20),
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: infoNews.imageUrl != null && infoNews.imageUrl!.isNotEmpty
            ? Image.network(
                infoNews.imageUrl!,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: kDarkComponentColor,
                  child: const Icon(
                    Icons.image_not_supported,
                    size: 64,
                    color: kSecondaryTextColor,
                  ),
                ),
              )
            : Container(
                color: kDarkComponentColor,
                child: const Icon(
                  Icons.article,
                  size: 64,
                  color: kSecondaryTextColor,
                ),
              ),
      ),
    );
  }

  Widget _buildContent() {
    final paragraphs = infoNews.content.split('\n\n');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: paragraphs.map((paragraph) {
        if (paragraph.trim().isEmpty) {
          return const SizedBox.shrink();
        }

        if (paragraph.trim().endsWith(':')) {
          return Padding(
            padding: const EdgeInsets.only(top: 20, bottom: 10),
            child: Text(
              paragraph.trim(),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: kTextColor,
                height: 1.4,
              ),
            ),
          );
        }

        if (paragraph.trim().startsWith('- ')) {
          final items = paragraph.split('\n');
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: items.map((item) {
              if (item.trim().startsWith('- ')) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8, left: 16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '• ',
                        style: TextStyle(
                          fontSize: 16,
                          color: kPrimaryColor,
                          height: 1.6,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          item.substring(2).trim(),
                          style: const TextStyle(
                            fontSize: 15,
                            color: kTextColor,
                            height: 1.6,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }
              return const SizedBox.shrink();
            }).toList(),
          );
        }

        if (RegExp(r'^\d+\.').hasMatch(paragraph.trim())) {
          final items = paragraph.split('\n');
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: items.map((item) {
              if (RegExp(r'^\d+\.').hasMatch(item.trim())) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8, left: 16),
                  child: Text(
                    item.trim(),
                    style: const TextStyle(
                      fontSize: 15,
                      color: kTextColor,
                      height: 1.6,
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            }).toList(),
          );
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Text(
            paragraph.trim(),
            style: const TextStyle(
              fontSize: 15,
              color: kTextColor,
              height: 1.7,
            ),
            textAlign: TextAlign.justify,
          ),
        );
      }).toList(),
    );
  }
}
