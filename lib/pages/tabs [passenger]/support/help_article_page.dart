import 'package:flutter/material.dart';
import '../../../../theme/app_colors.dart';
import 'help_center_models.dart';

// Light gray page background — always light, never dark.
const Color _kPageBg = Color(0xFFF4F4F8);

/// Shows a single help article: title, short description, and structured steps.
class HelpArticlePage extends StatelessWidget {
  final HelpArticle article;

  const HelpArticlePage({super.key, required this.article});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kPageBg,
      appBar: AppBar(
        backgroundColor: _kPageBg,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.lightBorder),
            ),
            child: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: AppColors.lightText,
              size: 16,
            ),
          ),
        ),
        title: const Text(
          'Help Center',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: AppColors.lightText,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 48),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Article title ──────────────────────────────────────────────
            Text(
              article.question,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.lightText,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 10),
            const Divider(color: AppColors.lightBorder, height: 1),
            const SizedBox(height: 14),

            // ── Short description ──────────────────────────────────────────
            if (article.answer.trim().isNotEmpty) ...[
              Text(
                article.answer,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.lightSubtext,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 24),
            ],

            // ── Steps ─────────────────────────────────────────────────────
            if (article.steps.isNotEmpty)
              _StepsList(steps: article.steps)
            else
              _LegacyBody(text: article.answer),
          ],
        ),
      ),
    );
  }
}

// ── Structured steps list ─────────────────────────────────────────────────────

class _StepsList extends StatelessWidget {
  final List<ArticleStep> steps;
  const _StepsList({required this.steps});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < steps.length; i++) ...[
          _StepBlock(step: steps[i]),
          if (i < steps.length - 1) const SizedBox(height: 20),
        ],
      ],
    );
  }
}

class _StepBlock extends StatelessWidget {
  final ArticleStep step;
  const _StepBlock({required this.step});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Solid purple circle with white step number
        Container(
          width: 28,
          height: 28,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: AppColors.primaryPurple,
            shape: BoxShape.circle,
          ),
          child: Text(
            '${step.order}',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (step.title.trim().isNotEmpty)
                Text(
                  step.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.lightText,
                    height: 1.4,
                  ),
                ),
              if (step.title.trim().isNotEmpty &&
                  step.description.trim().isNotEmpty)
                const SizedBox(height: 4),
              if (step.description.trim().isNotEmpty)
                Text(
                  step.description,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.lightSubtext,
                    height: 1.55,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Legacy plain-text fallback ────────────────────────────────────────────────
// Used when the article has no structured steps (older content).

class _LegacyBody extends StatelessWidget {
  final String text;
  const _LegacyBody({required this.text});

  @override
  Widget build(BuildContext context) {
    final lines = text.split('\n');
    final widgets = <Widget>[];

    for (final line in lines) {
      if (line.trim().isEmpty) {
        widgets.add(const SizedBox(height: 12));
        continue;
      }

      final stepMatch = RegExp(r'^(\d+)\.\s+(.+)$').firstMatch(line);
      if (stepMatch != null) {
        widgets
          ..add(_LegacyStepRow(
            number: stepMatch.group(1)!,
            text: stepMatch.group(2)!,
          ))
          ..add(const SizedBox(height: 10));
        continue;
      }

      if (line.startsWith('•')) {
        widgets
          ..add(_LegacyBulletRow(text: line.replaceFirst('•', '').trim()))
          ..add(const SizedBox(height: 8));
        continue;
      }

      widgets
        ..add(Text(
          line,
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.lightSubtext,
            height: 1.6,
          ),
        ))
        ..add(const SizedBox(height: 6));
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: widgets);
  }
}

class _LegacyStepRow extends StatelessWidget {
  final String number;
  final String text;
  const _LegacyStepRow({required this.number, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28,
          height: 28,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: AppColors.primaryPurple,
            shape: BoxShape.circle,
          ),
          child: Text(
            number,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 15,
                color: AppColors.lightText,
                height: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _LegacyBulletRow extends StatelessWidget {
  final String text;
  const _LegacyBulletRow({required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 8, left: 4),
          child: SizedBox(
            width: 6,
            height: 6,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.primaryPurple,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.lightSubtext,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }
}

