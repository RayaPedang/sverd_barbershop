import 'package:flutter/material.dart';
import 'package:sverd_barbershop/core/theme/colors.dart'; // <-- DIMODIFIKASI

class InfoNewsCard extends StatelessWidget {
  final String imagePath;
  final String title;

  const InfoNewsCard({super.key, required this.imagePath, required this.title});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8),
        child: Column(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                imagePath,
                height: 110,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 110,
                    width: double.infinity,
                    color: kDarkComponentColor,
                    child: const Icon(
                      Icons.image_not_supported,
                      color: kSecondaryTextColor,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: kTextColor,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
