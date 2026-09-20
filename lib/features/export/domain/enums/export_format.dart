/// Format file yang didukung untuk export/import laporan transaksi.
enum ExportFormat {
  pdf,
  csv,
  xls;

  String get label => switch (this) {
    ExportFormat.pdf => 'PDF',
    ExportFormat.csv => 'CSV',
    ExportFormat.xls => 'Excel',
  };

  String get extension => switch (this) {
    ExportFormat.pdf => 'pdf',
    ExportFormat.csv => 'csv',
    ExportFormat.xls => 'xlsx',
  };

  String get mimeType => switch (this) {
    ExportFormat.pdf => 'application/pdf',
    ExportFormat.csv => 'text/csv',
    ExportFormat.xls =>
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
  };
}
