class SalaryAnalysisResult {
  final bool hasSalary;
  final String currency;
  final double? minAmount;
  final double? maxAmount;
  final String period;
  final String rawText;
  final String formattedRange;

  const SalaryAnalysisResult({
    required this.hasSalary,
    this.currency = 'Unknown',
    this.minAmount,
    this.maxAmount,
    this.period = 'unknown',
    this.rawText = '',
    this.formattedRange = 'Not specified',
  });

  factory SalaryAnalysisResult.empty() {
    return const SalaryAnalysisResult(
      hasSalary: false,
      currency: 'Unknown',
      minAmount: null,
      maxAmount: null,
      period: 'unknown',
      rawText: '',
      formattedRange: 'Not specified',
    );
  }

  Map<String, dynamic> toMap() => {
        'hasSalary': hasSalary,
        'currency': currency,
        'minAmount': minAmount,
        'maxAmount': maxAmount,
        'period': period,
        'rawText': rawText,
        'formattedRange': formattedRange,
      };

  factory SalaryAnalysisResult.fromMap(Map<String, dynamic> map) =>
      SalaryAnalysisResult(
        hasSalary: map['hasSalary'] ?? false,
        currency: map['currency'] ?? 'Unknown',
        minAmount: (map['minAmount'] as num?)?.toDouble(),
        maxAmount: (map['maxAmount'] as num?)?.toDouble(),
        period: map['period'] ?? 'unknown',
        rawText: map['rawText'] ?? '',
        formattedRange: map['formattedRange'] ?? 'Not specified',
      );
}

/// Service that parses compensation and salary range details from job descriptions.
class SalaryAnalyzerService {
  /// Extracts salary details from [jobText].
  SalaryAnalysisResult parseSalary(String jobText) {
    if (jobText.trim().isEmpty) {
      return SalaryAnalysisResult.empty();
    }

    // 1. Check Rupee LPA / Lakhs pattern: e.g. ₹8 LPA, 10-15 LPA, 8 to 12 Lakhs per annum
    final lpaRegex = RegExp(
      r'(?:₹|INR|Rs\.?|Rupees)?\s*(\d+(?:\.\d+)?)\s*(?:-|to|\s+)\s*(\d+(?:\.\d+)?)\s*(?:LPA|Lakhs?|Lakh)',
      caseSensitive: false,
    );
    final singleLpaRegex = RegExp(
      r'(?:₹|INR|Rs\.?|Rupees)?\s*(\d+(?:\.\d+)?)\s*(?:LPA|Lakhs?|Lakh)',
      caseSensitive: false,
    );

    var lpaMatch = lpaRegex.firstMatch(jobText);
    if (lpaMatch != null) {
      final minL = double.parse(lpaMatch.group(1)!);
      final maxL = double.parse(lpaMatch.group(2)!);
      final raw = lpaMatch.group(0)!;
      return SalaryAnalysisResult(
        hasSalary: true,
        currency: 'INR',
        minAmount: minL * 100000,
        maxAmount: maxL * 100000,
        period: 'annual',
        rawText: raw,
        formattedRange: '₹${minL.toStringAsFixed(minL.truncateToDouble() == minL ? 0 : 1)} - ₹${maxL.toStringAsFixed(maxL.truncateToDouble() == maxL ? 0 : 1)} LPA',
      );
    }

    lpaMatch = singleLpaRegex.firstMatch(jobText);
    if (lpaMatch != null) {
      final valL = double.parse(lpaMatch.group(1)!);
      final raw = lpaMatch.group(0)!;
      return SalaryAnalysisResult(
        hasSalary: true,
        currency: 'INR',
        minAmount: valL * 100000,
        maxAmount: valL * 100000,
        period: 'annual',
        rawText: raw,
        formattedRange: '₹${valL.toStringAsFixed(valL.truncateToDouble() == valL ? 0 : 1)} LPA',
      );
    }

    // 2. Check Dollar Range pattern: e.g. $80,000 - $120,000 or $80k - $120k or $50/hr
    final dollarRangeRegex = RegExp(
      r'\$\s*(\d{1,3}(?:,\d{3})*|\d+)\s*(?:k|K)?\s*(?:-|to|\s+)\s*\$?\s*(\d{1,3}(?:,\d{3})*|\d+)\s*(k|K)?(?:\s*\/\s*(hr|hour|month|yr|year))?',
      caseSensitive: false,
    );
    final dollarMatch = dollarRangeRegex.firstMatch(jobText);
    if (dollarMatch != null) {
      String minStr = dollarMatch.group(1)!.replaceAll(',', '');
      String maxStr = dollarMatch.group(2)!.replaceAll(',', '');
      bool minHasK = jobText.substring(dollarMatch.start, dollarMatch.end).toLowerCase().contains('k');
      bool maxHasK = dollarMatch.group(3) != null || minHasK;

      double minVal = double.parse(minStr) * (minHasK ? 1000 : 1);
      double maxVal = double.parse(maxStr) * (maxHasK ? 1000 : 1);

      if (minVal < 1000 && minHasK) minVal *= 1000;
      if (maxVal < 1000 && maxHasK) maxVal *= 1000;

      final raw = dollarMatch.group(0)!;
      final periodUnit = dollarMatch.group(4)?.toLowerCase();
      String period = 'annual';
      if (periodUnit == 'hr' || periodUnit == 'hour') period = 'hourly';
      if (periodUnit == 'month') period = 'monthly';

      return SalaryAnalysisResult(
        hasSalary: true,
        currency: 'USD',
        minAmount: minVal,
        maxAmount: maxVal,
        period: period,
        rawText: raw,
        formattedRange: '\$${_formatNum(minVal)} - \$${_formatNum(maxVal)}${period == 'hourly' ? '/hr' : ''}',
      );
    }

    // 3. Single dollar amount, e.g. $100,000 / year or $100k
    final singleDollarRegex = RegExp(
      r'\$\s*(\d{1,3}(?:,\d{3})*|\d+)\s*(k|K)?(?:\s*\/\s*(hr|hour|month|yr|year))?',
      caseSensitive: false,
    );
    final singleDollarMatch = singleDollarRegex.firstMatch(jobText);
    if (singleDollarMatch != null) {
      final numStr = singleDollarMatch.group(1)!.replaceAll(',', '');
      final hasK = singleDollarMatch.group(2) != null;
      double val = double.parse(numStr) * (hasK ? 1000 : 1);
      final raw = singleDollarMatch.group(0)!;
      final periodUnit = singleDollarMatch.group(3)?.toLowerCase();
      String period = 'annual';
      if (periodUnit == 'hr' || periodUnit == 'hour') period = 'hourly';
      if (periodUnit == 'month') period = 'monthly';

      // Ignore small numbers that might be non-salary (e.g. $5 fee)
      if (val >= 15 || period == 'hourly') {
        return SalaryAnalysisResult(
          hasSalary: true,
          currency: 'USD',
          minAmount: val,
          maxAmount: val,
          period: period,
          rawText: raw,
          formattedRange: '\$${_formatNum(val)}${period == 'hourly' ? '/hr' : ''}',
        );
      }
    }

    return SalaryAnalysisResult.empty();
  }

  String _formatNum(double num) {
    if (num >= 1000) {
      final kVal = num / 1000;
      return '${kVal.toStringAsFixed(kVal.truncateToDouble() == kVal ? 0 : 1)}k';
    }
    return num.toStringAsFixed(0);
  }
}
