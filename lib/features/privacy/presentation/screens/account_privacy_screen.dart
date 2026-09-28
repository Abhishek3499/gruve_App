import 'package:flutter/material.dart';
import 'package:gruve_app/core/utils/responsive_extensions.dart';
import 'package:gruve_app/features/privacy/constants/privacy_constants.dart';
import 'package:gruve_app/features/privacy/data/account_type_service.dart';
import 'package:gruve_app/features/privacy/presentation/widgets/account_privacy_header.dart';
import 'package:gruve_app/features/privacy/presentation/widgets/privacy_card.dart';
import 'package:gruve_app/features/privacy/presentation/widgets/privacy_toggle_tile.dart';
import 'package:gruve_app/features/privacy/presentation/widgets/account_privacy_footer.dart';
import 'package:gruve_app/core/constants/app_colors.dart';

class AccountPrivacyScreen extends StatefulWidget {
  const AccountPrivacyScreen({super.key, this.initialAccountType = 'public'});

  final String initialAccountType;

  @override
  State<AccountPrivacyScreen> createState() => _AccountPrivacyScreenState();
}

class _AccountPrivacyScreenState extends State<AccountPrivacyScreen> {
  final _service = AccountTypeService();

  late bool _isPrivate;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _isPrivate = widget.initialAccountType == 'private';
  }

  Future<void> _onToggle(bool value) async {
    // Optimistic update
    setState(() {
      _isPrivate = value;
      _loading = true;
    });

    try {
      final updated = await _service.setAccountType(
        value ? 'private' : 'public',
      );
      if (mounted) {
        setState(() => _isPrivate = updated == 'private');
      }
    } catch (_) {
      // Revert on failure
      if (mounted) {
        setState(() => _isPrivate = !value);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update account type. Please try again.')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final option = PrivacyConstants.privacyOptions.first;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment(0.8, -1.0),
            end: Alignment(-0.8, 1.0),
            colors: [AppColors.deepPlum, Color(0xFF210C26), Color(0xFF000000)],
            stops: [0.0, 0.3, 1.0],
          ),
        ),
        child: SafeArea(
          child: SizedBox(
            height: double.infinity,
            child: Column(
              children: [
                const AccountPrivacyHeader(),
                SizedBox(height: context.rh(12)),
                PrivacyCard(
                  child: IgnorePointer(
                    ignoring: _loading,
                    child: Opacity(
                      opacity: _loading ? 0.6 : 1.0,
                      child: PrivacyToggleTile(
                        title: option.title,
                        description: option.description,
                        value: _isPrivate,
                        onChanged: _onToggle,
                      ),
                    ),
                  ),
                ),
                const Spacer(),
                const AccountPrivacyFooter(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
