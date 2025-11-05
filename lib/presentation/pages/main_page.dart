import 'package:flutter/material.dart';
import 'package:sverd_barbershop/presentation/pages/reservation/reservation_page.dart';
import 'package:sverd_barbershop/presentation/pages/home/home_tab.dart';
import 'package:sverd_barbershop/presentation/pages/profile/profile_tab.dart';
import 'package:sverd_barbershop/core/theme/colors.dart';

class MainPage extends StatefulWidget {
  final String username;

  const MainPage({super.key, required this.username});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _selectedIndex = 0;
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      HomeTab(
        onReservationTapped: () => _onItemTapped(1),
        username: widget.username,
      ),
      const ReservationPage(),
      const ProfileTab(),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  String _getTitle(int index) {
    switch (index) {
      case 0:
        return 'Sverd Barbershop';
      case 1:
        return 'Pilih Cabang';
      case 2:
        return 'Profil';
      default:
        return 'Sverd';
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color iconColorInactive = kLightTextColor.withOpacity(0.7);
    const Color iconColorActive = kPrimaryColor;
    const double iconSize = 24.0;

    return Scaffold(
      appBar: AppBar(
        title: _selectedIndex == 0
            ? Image.asset(
                'assets/images/logo_sverd.png',
                height: 30,
                errorBuilder: (context, error, stackTrace) {
                  return const Text(
                    "SVERD",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: kTextColor,
                    ),
                  );
                },
              )
            : Text(
                _getTitle(_selectedIndex),
                style: const TextStyle(
                  color: kTextColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
        centerTitle: true,
        backgroundColor: kBackgroundColor,
        elevation: 0,
      ),
      body: IndexedStack(index: _selectedIndex, children: _pages),
      bottomNavigationBar: BottomNavigationBar(
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home_filled, color: iconColorInactive),
            activeIcon: Icon(Icons.home_filled, color: iconColorActive),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Image.asset(
              'assets/images/icons/nav_bookings.png',
              height: iconSize,
              color: iconColorInactive,
              errorBuilder: (context, error, stackTrace) =>
                  Icon(Icons.content_cut, color: iconColorInactive),
            ),
            activeIcon: Image.asset(
              'assets/images/icons/nav_bookings.png',
              height: iconSize,
              color: iconColorActive,
              errorBuilder: (context, error, stackTrace) =>
                  Icon(Icons.content_cut, color: iconColorActive),
            ),
            label: 'Reservasi',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person, color: iconColorInactive),
            activeIcon: Icon(Icons.person, color: iconColorActive),
            label: 'Profil',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: iconColorActive,
        unselectedItemColor: iconColorInactive,
        onTap: _onItemTapped,
        backgroundColor: kDarkBlockColor,
        type: BottomNavigationBarType.fixed,
        elevation: 5,
      ),
    );
  }
}
