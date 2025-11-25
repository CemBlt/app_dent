import 'package:flutter/material.dart';

import '../models/favorite.dart';
import '../services/auth_service.dart';
import '../services/json_service.dart';
import '../theme/app_theme.dart';
import '../screens/login_screen.dart';

class FavoriteButton extends StatefulWidget {
  final FavoriteType type;
  final String targetId;
  final bool isFavorite;
  final VoidCallback? onChanged;

  const FavoriteButton({
    super.key,
    required this.type,
    required this.targetId,
    required this.isFavorite,
    this.onChanged,
  });

  @override
  State<FavoriteButton> createState() => _FavoriteButtonState();
}

class _FavoriteButtonState extends State<FavoriteButton> {
  late bool _isFavorite;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _isFavorite = widget.isFavorite;
  }

  @override
  void didUpdateWidget(covariant FavoriteButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isFavorite != widget.isFavorite) {
      _isFavorite = widget.isFavorite;
    }
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: _isLoading
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(
              _isFavorite ? Icons.favorite : Icons.favorite_border,
              color: _isFavorite ? AppTheme.warningOrange : AppTheme.iconSecondary,
            ),
      onPressed: _isLoading ? null : _toggleFavorite,
      tooltip: _isFavorite ? 'Favorilerden çıkar' : 'Favorilere ekle',
    );
  }

  Future<void> _toggleFavorite() async {
    if (!AuthService.isAuthenticated) {
      final proceed = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (_) => LoginScreen(
            onLoginSuccess: () => Navigator.pop(context, true),
          ),
        ),
      );
      if (proceed != true) return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final newState = await JsonService.toggleFavorite(
        targetId: widget.targetId,
        type: widget.type,
      );
      if (!mounted) return;
      setState(() {
        _isFavorite = newState;
        _isLoading = false;
      });
      widget.onChanged?.call();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            newState ? 'Favorilere eklendi' : 'Favorilerden çıkarıldı',
          ),
          backgroundColor: newState ? AppTheme.successGreen : Colors.orange,
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Favori güncellenemedi: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}


