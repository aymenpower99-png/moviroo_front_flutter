class FaqEntryData {
  final String questionKey;
  final String answerKey;

  const FaqEntryData({required this.questionKey, required this.answerKey});
}

class FaqCategoryData {
  final String titleKey;
  final List<FaqEntryData> entries;

  const FaqCategoryData({required this.titleKey, required this.entries});
}