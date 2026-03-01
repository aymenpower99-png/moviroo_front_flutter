import 'package:flutter/material.dart';
import '../../../../../theme/app_colors.dart';
import '../../../../../theme/app_text_styles.dart';
import '../../../../../l10n/app_localizations.dart';

// ── Currency model ────────────────────────────────────────────────────────────

class _Currency {
  final String code;
  final String name;
  final String symbol;

  const _Currency({
    required this.code,
    required this.name,
    required this.symbol,
  });
}

const List<_Currency> _currencies = [
  _Currency(code: 'USD', name: 'US Dollar',         symbol: '\$'),
  _Currency(code: 'EUR', name: 'Euro',               symbol: '€'),
  _Currency(code: 'GBP', name: 'British Pound',      symbol: '£'),
  _Currency(code: 'TND', name: 'Tunisian Dinar',     symbol: 'د.ت'),
  _Currency(code: 'DZD', name: 'Algerian Dinar',     symbol: 'د.ج'),
  _Currency(code: 'LYD', name: 'Libyan Dinar',       symbol: 'ل.د'),
  _Currency(code: 'MAD', name: 'Moroccan Dirham',    symbol: 'د.م.'),
  _Currency(code: 'SAR', name: 'Saudi Riyal',        symbol: '﷼'),
  _Currency(code: 'AED', name: 'UAE Dirham',         symbol: 'د.إ'),
  _Currency(code: 'EGP', name: 'Egyptian Pound',     symbol: 'ج.م'),
];

// ── Currency page ─────────────────────────────────────────────────────────────

class CurrencyPage extends StatefulWidget {
  const CurrencyPage({super.key});

  @override
  State<CurrencyPage> createState() => _CurrencyPageState();
}

class _CurrencyPageState extends State<CurrencyPage> {
  String _selectedCode = 'USD';
  String _searchQuery = '';

  List<_Currency> get _filtered => _currencies
      .where((c) =>
          c.code.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          c.name.toLowerCase().contains(_searchQuery.toLowerCase()))
      .toList();

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context).translate;

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      body: SafeArea(
        child: Column(
          children: [
            // ── Top bar ──────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.maybePop(context),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.surface(context),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.border(context)),
                      ),
                      child: Icon(
                        Icons.chevron_left_rounded,
                        size: 22,
                        color: AppColors.text(context),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      t('currency'),
                      textAlign: TextAlign.center,
                      style: AppTextStyles.pageTitle(context),
                    ),
                  ),
                  const SizedBox(width: 36),
                ],
              ),
            ),

            // ── Search bar ───────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.surface(context),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border(context)),
                ),
                child: TextField(
                  onChanged: (v) => setState(() => _searchQuery = v),
                  style: AppTextStyles.settingsItem(context),
                  cursorColor: AppColors.text(context),
                  decoration: InputDecoration(
                    hintText: t('search'),
                    hintStyle: AppTextStyles.settingsItem(context)
                        .copyWith(color: AppColors.subtext(context)),
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      color: AppColors.subtext(context),
                      size: 20,
                    ),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ── List ─────────────────────────────────────────────
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: _filtered.length,
                separatorBuilder: (_, __) =>
                    Divider(height: 1, color: AppColors.border(context)),
                itemBuilder: (context, index) {
                  final currency = _filtered[index];
                  final isSelected = currency.code == _selectedCode;

                  return GestureDetector(
                    onTap: () {
                      setState(() => _selectedCode = currency.code);
                      // TODO: persist selected currency via your state management
                    },
                    behavior: HitTestBehavior.opaque,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Row(
                        children: [
                          // Symbol badge
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: AppColors.surface(context),
                              borderRadius: BorderRadius.circular(10),
                              border:
                                  Border.all(color: AppColors.border(context)),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              currency.symbol,
                              style: AppTextStyles.settingsItem(context)
                                  .copyWith(fontWeight: FontWeight.w600),
                            ),
                          ),

                          const SizedBox(width: 14),

                          // Name & code
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  currency.name,
                                  style: AppTextStyles.settingsItem(context),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  currency.code,
                                  style: AppTextStyles.settingsItem(context)
                                      .copyWith(
                                    color: AppColors.subtext(context),
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Checkmark
                          if (isSelected)
                            Icon(
                              Icons.check_rounded,
                              color: AppColors.text(context),
                              size: 20,
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}