import 'dart:async';
import 'package:flutter/material.dart';
import 'package:sverd_barbershop/core/models/info_news.dart';
import 'package:sverd_barbershop/core/services/api_service.dart';
import 'package:sverd_barbershop/core/theme/colors.dart';
import 'package:sverd_barbershop/presentation/pages/info_news/info_news_detail_page.dart';

class InfoNewsPage extends StatefulWidget {
  const InfoNewsPage({super.key});

  @override
  State<InfoNewsPage> createState() => _InfoNewsPageState();
}

class _InfoNewsPageState extends State<InfoNewsPage> {
  final ApiService _apiService = ApiService();
  List<InfoNews> _infoNewsList = [];
  bool _isLoading = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _fetchInfoNews();
  }

  Future<void> _fetchInfoNews() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      print('🔵 [API] Fetching info/news from: InfoNewsPage');
      final List<InfoNews> infoNews = await _apiService.fetchInfoNews();

      if (mounted) {
        setState(() {
          _infoNewsList = infoNews;
          _isLoading = false;
        });
      }

      print('[API] Berhasil load ${infoNews.length} info/news');
    } on TimeoutException {
      if (mounted) {
        setState(() {
          _error = 'Request timeout!\nPastikan Laragon running.';
          _isLoading = false;
        });
      }
      print('[API] Timeout');
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Error: $e';
          _isLoading = false;
        });
      }
      print('[API] Error: $e');
    }
  }

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
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: kPrimaryColor),
      );
    }

    if (_error.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
              const SizedBox(height: 16),
              Text(
                _error,
                textAlign: TextAlign.center,
                style: const TextStyle(color: kTextColor, fontSize: 14),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _fetchInfoNews,
                icon: const Icon(Icons.refresh),
                label: const Text('Coba Lagi'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimaryColor,
                  foregroundColor: kLightTextColor,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_infoNewsList.isEmpty) {
      return const Center(
        child: Text(
          'Tidak ada info & news tersedia',
          style: TextStyle(color: kSecondaryTextColor),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _infoNewsList.length,
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final infoNews = _infoNewsList[index];
        return _buildInfoCard(infoNews);
      },
    );
  }

  Widget _buildInfoCard(InfoNews infoNews) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => InfoNewsDetailPage(infoNews: infoNews),
          ),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 180,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: infoNews.imageUrl != null && infoNews.imageUrl!.isNotEmpty
                  ? Image.network(
                      infoNews.imageUrl!,
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: kDarkComponentColor,
                        child: const Icon(
                          Icons.image_not_supported,
                          size: 48,
                          color: kSecondaryTextColor,
                        ),
                      ),
                    )
                  : Container(
                      color: kDarkComponentColor,
                      child: const Icon(
                        Icons.article,
                        size: 48,
                        color: kSecondaryTextColor,
                      ),
                    ),
            ),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
                ),
              ),
            ),
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: Text(
                infoNews.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(
                      color: Colors.black,
                      offset: Offset(0, 1),
                      blurRadius: 3,
                    ),
                  ],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
