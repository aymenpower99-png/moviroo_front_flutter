import 'package:flutter/material.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_text_styles.dart';
import '../../../../services/help_center_service.dart';
import 'help_center_models.dart';
import 'help_article_page.dart';

/// Shows every article across all categories as a flat, scrollable list.
/// Reached via the "View All" link on the support page.
class HelpAllArticlesPage extends StatefulWidget {
  const HelpAllArticlesPage({super.key});

  @override
  State<HelpAllArticlesPage> createState() => _HelpAllArticlesPageState();
}

class _HelpAllArticlesPageState extends State<HelpAllArticlesPage> {
  final _service = HelpCenterService();
  late Future<List<HelpArticle>> _future;

  @override
  void initState() {
    super.initState();
    _future = _service.fetchAllArticles();
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
        title: Text(
          'All Articles',
          style: AppTextStyles.pageTitle(context).copyWith(
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: FutureBuilder<List<HelpArticle>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: AppColors.primaryPurple,
                strokeWidth: 2,
              ),
            );
          }

          if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  'No articles available yet.',
                  style: AppTextStyles.bodyMedium(context),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final articles = snapshot.data!;

          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: articles.length,
            separatorBuilder: (_, __) => Divider(
              height: 1,
              color: AppColors.border(context),
              indent: 20,
              endIndent: 20,
            ),
            itemBuilder: (context, i) {
              final article = articles[i];
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
                    vertical: 16,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          article.question,
                          style: AppTextStyles.bodyMedium(context).copyWith(
                            fontWeight: FontWeight.w500,
                            height: 1.4,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: AppColors.subtext(context),
                        size: 20,
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
