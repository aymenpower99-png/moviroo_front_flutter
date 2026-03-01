import 'package:flutter/material.dart';
import 'support_models.dart';

const List<FaqCategoryData> kFaqCategories = [
  FaqCategoryData(
    titleKey: 'faq_booking_title',
    entries: [
      FaqEntryData(questionKey: 'faq_booking_q1', answerKey: 'faq_booking_a1'),
      FaqEntryData(questionKey: 'faq_booking_q2', answerKey: 'faq_booking_a2'),
      FaqEntryData(questionKey: 'faq_booking_q3', answerKey: 'faq_booking_a3'),
    ],
  ),
  FaqCategoryData(
    titleKey: 'faq_payments_title',
    entries: [
      FaqEntryData(questionKey: 'faq_payments_q1', answerKey: 'faq_payments_a1'),
      FaqEntryData(questionKey: 'faq_payments_q2', answerKey: 'faq_payments_a2'),
      FaqEntryData(questionKey: 'faq_payments_q3', answerKey: 'faq_payments_a3'),
    ],
  ),
  FaqCategoryData(
    titleKey: 'faq_account_title',
    entries: [
      FaqEntryData(questionKey: 'faq_account_q1', answerKey: 'faq_account_a1'),
      FaqEntryData(questionKey: 'faq_account_q2', answerKey: 'faq_account_a2'),
      FaqEntryData(questionKey: 'faq_account_q3', answerKey: 'faq_account_a3'),
    ],
  ),
];

const List<IconData> kFaqIcons = [
  Icons.calendar_month_rounded,
  Icons.wallet_rounded,
  Icons.shield_outlined,
];