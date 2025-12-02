import 'dart:async';
import 'package:flutter/material.dart';
import 'package:sverd_barbershop/core/models/info_news.dart';
import 'package:sverd_barbershop/core/services/api_service.dart';
import 'package:sverd_barbershop/core/theme/colors.dart';
import 'package:sverd_barbershop/presentation/pages/bookings/your_reservation_page.dart';
import 'package:sverd_barbershop/presentation/pages/info_news/info_news_page.dart';
import 'package:sverd_barbershop/presentation/pages/info_news/info_news_detail_page.dart';

class HomeTab extends StatefulWidget {
  final VoidCallback onReservationTapped;
  final String username;

  const HomeTab({
    super.key,
    required this.onReservationTapped,
    required this.username,
  });

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  int _carouselIndex = 0;
  final PageController _pageController = PageController();

  final List<String> _carouselImages = [
    'assets/images/photos/carousel_1.jpg',
    'assets/images/photos/carousel_2.jpg',
    'assets/images/photos/carousel_3.jpg',
  ];

  final ApiService _apiService = ApiService();
  List<InfoNews> _infoNewsList = [];
  bool _isLoadingNews = true;

  @override
  void initState() {
    super.initState();
    _fetchInfoNews();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  //fetch info/news dari API
  Future<void> _fetchInfoNews() async {
    try {
      final List<InfoNews> infoNews = await _apiService.fetchInfoNews();

      if (mounted) {
        setState(() {
          _infoNewsList = infoNews;
          _isLoadingNews = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingNews = false;
        });
      }
      print('Error loading info/news from HomeTab: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 24),
            _buildWelcome(widget.username),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Divider(
                color: kSecondaryTextColor.withAlpha(76),
                height: 1,
              ),
            ),
            const SizedBox(height: 24),
            _buildMenuSection(),
            const SizedBox(height: 30),
            _buildImageCarousel(),
            const SizedBox(height: 30),
            _buildInfoNewsSection(),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcome(String username) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(
            fontSize: 16,
            color: kTextColor,
            fontFamily: 'Poppins',
          ),
          children: [
            const TextSpan(text: 'Selamat Datang, '),
            TextSpan(
              text: username,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Menu',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: kTextColor,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 20.0),
            decoration: BoxDecoration(
              color: kDarkBlockColor,
              borderRadius: BorderRadius.circular(20.0),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMenuItem(
                  icon: Icons.content_cut_rounded,
                  label: 'Reservasi',
                  onTap: widget.onReservationTapped,
                ),
                _buildMenuItem(
                  icon: Icons.article_rounded,
                  label: 'Informasi & Berita',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const InfoNewsPage(),
                      ),
                    );
                  },
                ),
                _buildMenuItem(
                  icon: Icons.calendar_today_rounded,
                  label: 'Reservasiku',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const YourReservationPage(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: kDarkComponentColor,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: kLightTextColor, size: 28),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: const TextStyle(color: kLightTextColor, fontSize: 13),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageCarousel() {
    return Column(
      children: [
        SizedBox(
          height: 200,
          child: PageView.builder(
            controller: _pageController,
            itemCount: _carouselImages.length,
            onPageChanged: (index) {
              setState(() {
                _carouselIndex = index;
              });
            },
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20.0),
                  child: Image.asset(
                    _carouselImages[index],
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: kDarkComponentColor,
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.image_not_supported,
                        color: kSecondaryTextColor,
                        size: 48,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_carouselImages.length, (index) {
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 4.0),
              height: 8.0,
              width: 8.0,
              decoration: BoxDecoration(
                color: _carouselIndex == index
                    ? kPrimaryColor
                    : kSecondaryTextColor.withAlpha(128),
                shape: BoxShape.circle,
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildInfoNewsSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // ----------------------------------------------------
              // PERBAIKAN: Bungkus Text dengan Expanded & tambahkan ellipsis
              // ----------------------------------------------------
              const Expanded(
                child: Text(
                  'Informasi & Berita',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: kTextColor,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const InfoNewsPage(),
                    ),
                  );
                },
                child: const Text(
                  'Lihat Semua',
                  style: TextStyle(
                    color: kPrimaryColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_isLoadingNews)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32.0),
                child: CircularProgressIndicator(color: kPrimaryColor),
              ),
            )
          else if (_infoNewsList.isNotEmpty)
            Column(
              children: _infoNewsList.take(2).map((infoNews) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _buildInfoNewsCard(infoNews),
                );
              }).toList(),
            )
          else
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32.0),
                child: Text(
                  'Tidak ada informasi atau berita yang tersedia',
                  style: TextStyle(color: kSecondaryTextColor),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoNewsCard(InfoNews infoNews) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => InfoNewsDetailPage(infoNews: infoNews),
          ),
        );
      },
      borderRadius: BorderRadius.circular(15.0),
      child: Container(
        height: 150,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15.0),
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
              borderRadius: BorderRadius.circular(15.0),
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
                          size: 40,
                          color: kSecondaryTextColor,
                        ),
                      ),
                    )
                  : Container(
                      color: kDarkComponentColor,
                      child: const Icon(
                        Icons.article,
                        size: 40,
                        color: kSecondaryTextColor,
                      ),
                    ),
            ),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15.0),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
                ),
              ),
            ),
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: Text(
                infoNews.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
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
