import 'package:flutter/material.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_text_styles.dart';
import '../../../../services/help_center_service.dart';
import '../../../../main.dart';
import '../../../../l10n/app_localizations.dart';
import 'help_center_models.dart';
import 'help_article_page.dart';

/// Displays a scrollable list of all questions in [category].
/// Each row is plain text separated by a thin Divider.
/// Tapping a row navigates to [HelpArticlePage].
class HelpCategoryPage extends StatefulWidget {
  final HelpCategory category;

  const HelpCategoryPage({super.key, required this.category});

  @override
  State<HelpCategoryPage> createState() => _HelpCategoryPageState();
}

class _HelpCategoryPageState extends State<HelpCategoryPage> {
  late HelpCenterService _service;
  List<HelpArticle>? _articles;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _service = HelpCenterService(lang: localeProvider.locale.languageCode);
    // Use cache if warm → instant render, no spinner
    final cached = HelpCenterService.cachedArticlesByCategory(
      widget.category.id,
    );
    if (cached != null) {
      _articles = cached;
      // Silently refresh in background
      _refresh();
    } else {
      _loading = true;
      _fetch();
    }
  }

  Future<void> _fetch() async {
    try {
      final articles = await _service.fetchArticlesByCategory(
        widget.category.id,
      );
      if (mounted)
        setState(() {
          _articles = articles;
          _loading = false;
        });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _refresh() async {
    try {
      final articles = await _service.fetchArticlesByCategory(
        widget.category.id,
      );
      if (mounted) setState(() => _articles = articles);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(
        backgroundColor: AppColors.bg(context),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.surface(context),
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.border(context)),
            ),
            child: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: AppColors.text(context),
              size: 16,
            ),
          ),
        ),
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.iconBg(context),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                widget.category.icon,
                color: AppColors.primaryPurple,
                size: 16,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                AppLocalizations.of(
                  context,
                ).translate('hc_cat_${widget.category.id}'),
                style: AppTextStyles.pageTitle(
                  context,
                ).copyWith(fontSize: 18, fontWeight: FontWeight.w700),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(
                color: AppColors.primaryPurple,
                strokeWidth: 2,
              ),
            )
          : (_articles == null || _articles!.isEmpty)
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  'No articles available yet.',
                  style: AppTextStyles.bodyMedium(context),
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: _articles!.length,
              separatorBuilder: (_, __) => Divider(
                height: 1,
                color: AppColors.border(context),
                indent: 20,
                endIndent: 20,
              ),
              itemBuilder: (context, i) {
                final article = _articles![i];
                return InkWell(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => HelpArticlePage(article: article),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 18,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            article.question,
                            style: AppTextStyles.bodyMedium(context).copyWith(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              height: 1.4,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(
                          Icons.chevron_right_rounded,
                          color: AppColors.subtext(context),
                          size: 22,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
