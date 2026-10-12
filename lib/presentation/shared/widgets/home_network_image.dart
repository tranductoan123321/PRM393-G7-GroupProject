import 'package:flutter/material.dart';

const _cardColor = Color(0xFFDEE3EB);
const _ink = Color(0xFF001D34);

class HomeNetworkImage extends StatelessWidget {
  const HomeNetworkImage(
    this.url, {
    required this.fit,
    required this.fallbackIcon,
    this.width,
    this.height,
    super.key,
  });

  final String url;
  final BoxFit fit;
  final IconData fallbackIcon;
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    if (url.isEmpty) {
      return _fallback();
    }
    return Image.network(
      url,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (context, error, stackTrace) => _fallback(),
    );
  }

  Widget _fallback() => Container(
    width: width,
    height: height,
    color: _cardColor,
    alignment: Alignment.center,
    child: Icon(fallbackIcon, color: _ink),
  );
}
