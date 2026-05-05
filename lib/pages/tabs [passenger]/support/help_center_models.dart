import 'package:flutter/material.dart';

/// A help center category returned by the backend.
/// [articleCount] is computed server-side and drives the "N articles" label.
class HelpCategory {
  final String id;
  final String name;
  final IconData icon; // mapped client-side from category id/type
  final int articleCount;

  const HelpCategory({
    required this.id,
    required this.name,
    required this.icon,
    required this.articleCount,
  });

  factory HelpCategory.fromJson(Map<String, dynamic> json, IconData icon) {
    return HelpCategory(
      id: (json['key'] ?? json['id'] ?? '') as String,
      name: (json['label'] ?? json['name'] ?? '') as String,
      icon: icon,
      articleCount: (json['articleCount'] ?? 0) as int,
    );
  }
}

/// A single step inside an article (structured content from the backend).
class ArticleStep {
  final int order;
  final String title;
  final String description;

  const ArticleStep({
    required this.order,
    required this.title,
    required this.description,
  });

  factory ArticleStep.fromJson(Map<String, dynamic> json) {
    return ArticleStep(
      order: (json['order'] ?? 0) as int,
      title: (json['title'] ?? '') as String,
      description: (json['description'] ?? '') as String,
    );
  }
}

/// A single help article (question + answer) belonging to a category.
class HelpArticle {
  final String id;
  final String categoryId;
  final String question;   // = title from backend
  final String answer;     // = description (intro text) from backend
  final List<ArticleStep> steps;

  const HelpArticle({
    required this.id,
    required this.categoryId,
    required this.question,
    required this.answer,
    this.steps = const [],
  });

  factory HelpArticle.fromJson(Map<String, dynamic> json) {
    final rawSteps = json['steps'] as List<dynamic>? ?? [];
    return HelpArticle(
      id: (json['id'] ?? '') as String,
      categoryId: (json['categoryKey'] ?? '') as String,
      question: (json['title'] ?? '') as String,
      answer: (json['description'] ?? '') as String,
      steps: rawSteps
          .map((s) => ArticleStep.fromJson(s as Map<String, dynamic>))
          .toList()
        ..sort((a, b) => a.order.compareTo(b.order)),
    );
  }
}

