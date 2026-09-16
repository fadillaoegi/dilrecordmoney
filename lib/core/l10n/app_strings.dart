import 'app_locale.dart';

/// Seluruh teks UI untuk satu bahasa.
///
/// Ditulis manual (tanpa codegen/ARB) supaya konsisten dengan gaya project
/// yang lain — sama seperti `CurrencyFormatter`/`DateFormatter` yang juga
/// tidak bergantung pada paket `intl`.
///
/// Diakses lewat [AppStrings.t]; bahasa aktif ditukar oleh [AppStrings.use]
/// dari root widget, tepat sebelum widget tree dibangun ulang (pola yang
/// sama dengan pergantian palet warna di `AppColors`).
class AppStrings {
  const AppStrings({
    required this.appTagline,
    required this.cancel,
    required this.save,
    required this.delete,
    required this.update,
    required this.done,
    required this.choose,
    required this.settings,
    required this.language,
    required this.appearance,
    required this.themeSystem,
    required this.themeLight,
    required this.themeDark,
    required this.totalBalance,
    required this.income,
    required this.expense,
    required this.transactions,
    required this.recordsCount,
    required this.noTransactionsTitle,
    required this.noTransactionsBody,
    required this.loadFailed,
    required this.transactionDeleted,
    required this.undo,
    required this.recordTransaction,
    required this.daily,
    required this.weekly,
    required this.monthly,
    required this.yearly,
    required this.editTransaction,
    required this.amountCaps,
    required this.tapToTypeAmount,
    required this.category,
    required this.paymentMethod,
    required this.noteOptional,
    required this.noteHistoryCaps,
    required this.deleteTransactionQuestion,
    required this.deleteIrreversible,
    required this.transactionSaved,
    required this.transactionUpdated,
    required this.thousandUnit,
    required this.millionUnit,
    required this.billionsUnit,
    required this.monthlyBudget,
    required this.used,
    required this.budget,
    required this.setBudget,
    required this.remainingPrefix,
    required this.overBudgetPrefix,
    required this.overBudgetSuffix,
    required this.budgetForPrefix,
    required this.clearToDeleteBudget,
    required this.backupData,
    required this.exportBackup,
    required this.importBackup,
    required this.importQuestion,
    required this.importWarning,
    required this.backupImported,
    required this.backupActionFailed,
    required this.backupExplain,
    required this.safeToSwitchPhone,
    required this.backupFileDesc,
    required this.backupShareTitle,
    required this.preparingBackup,
    required this.savingDailyBackup,
    required this.restoringBackup,
    required this.skip,
    required this.next,
    required this.startNow,
    required this.slide1Title,
    required this.slide1Body,
    required this.slide2Title,
    required this.slide2Body,
    required this.slide3Title,
    required this.slide3Body,
    required this.catFood,
    required this.catTransport,
    required this.catShopping,
    required this.catBills,
    required this.catEntertainment,
    required this.catHealth,
    required this.catEducation,
    required this.catSports,
    required this.catVape,
    required this.catOther,
    required this.catSalary,
    required this.catBonus,
    required this.catBusiness,
    required this.catGift,
    required this.catRefund,
    required this.catFreelance,
    required this.walletCash,
    required this.walletBank,
    required this.walletEwallet,
    required this.months,
    required this.monthsFull,
    required this.days,
    required this.today,
    required this.yesterday,
  });

  // Umum
  final String appTagline;
  final String cancel;
  final String save;
  final String delete;
  final String update;
  final String done;
  final String choose;

  // Pengaturan
  final String settings;
  final String language;
  final String appearance;
  final String themeSystem;
  final String themeLight;
  final String themeDark;

  // Beranda
  final String totalBalance;
  final String income;
  final String expense;
  final String transactions;
  final String recordsCount;
  final String noTransactionsTitle;
  final String noTransactionsBody;
  final String loadFailed;
  final String transactionDeleted;
  final String undo;
  final String recordTransaction;

  // Periode
  final String daily;
  final String weekly;
  final String monthly;
  final String yearly;

  // Input transaksi
  final String editTransaction;
  final String amountCaps;
  final String tapToTypeAmount;
  final String category;
  final String paymentMethod;
  final String noteOptional;
  final String noteHistoryCaps;
  final String deleteTransactionQuestion;
  final String deleteIrreversible;
  final String transactionSaved;
  final String transactionUpdated;
  final String thousandUnit;
  final String millionUnit;
  final String billionsUnit;

  // Anggaran
  final String monthlyBudget;
  final String used;
  final String budget;
  final String setBudget;
  final String remainingPrefix;
  final String overBudgetPrefix;
  final String overBudgetSuffix;
  final String budgetForPrefix;
  final String clearToDeleteBudget;

  // Backup
  final String backupData;
  final String exportBackup;
  final String importBackup;
  final String importQuestion;
  final String importWarning;
  final String backupImported;
  final String backupActionFailed;
  final String backupExplain;
  final String safeToSwitchPhone;
  final String backupFileDesc;
  final String backupShareTitle;
  final String preparingBackup;
  final String savingDailyBackup;
  final String restoringBackup;

  // Onboarding
  final String skip;
  final String next;
  final String startNow;
  final String slide1Title;
  final String slide1Body;
  final String slide2Title;
  final String slide2Body;
  final String slide3Title;
  final String slide3Body;

  // Kategori
  final String catFood;
  final String catTransport;
  final String catShopping;
  final String catBills;
  final String catEntertainment;
  final String catHealth;
  final String catEducation;
  final String catSports;
  final String catVape;
  final String catOther;
  final String catSalary;
  final String catBonus;
  final String catBusiness;
  final String catGift;
  final String catRefund;
  final String catFreelance;

  // Dompet / metode pembayaran
  final String walletCash;
  final String walletBank;
  final String walletEwallet;

  // Tanggal
  final List<String> months;
  final List<String> monthsFull;
  final List<String> days;
  final String today;
  final String yesterday;

  // ── Bahasa aktif ───────────────────────────────────────────────────────────

  static AppStrings _active = _idStrings;

  /// Teks untuk bahasa yang sedang dipakai.
  static AppStrings get t => _active;

  static void use(AppLocale locale) {
    _active = switch (locale) {
      AppLocale.id => _idStrings,
      AppLocale.en => _enStrings,
      AppLocale.zh => _zhStrings,
      AppLocale.ja => _jaStrings,
    };
  }
}

// ── Indonesia (default) ──────────────────────────────────────────────────────

const AppStrings _idStrings = AppStrings(
  appTagline: 'Teman catat keuanganmu',
  cancel: 'Batal',
  save: 'Simpan',
  delete: 'Hapus',
  update: 'Perbarui',
  done: 'Selesai',
  choose: 'Pilih',
  settings: 'Pengaturan',
  language: 'Bahasa',
  appearance: 'Tampilan',
  themeSystem: 'Ikut Sistem',
  themeLight: 'Terang',
  themeDark: 'Gelap',
  totalBalance: 'Total Saldo',
  income: 'Pemasukan',
  expense: 'Pengeluaran',
  transactions: 'Transaksi',
  recordsCount: 'catatan',
  noTransactionsTitle: 'Belum ada transaksi',
  noTransactionsBody:
      'Belum ada transaksi di periode ini.\nKetuk "Catat Transaksi" untuk menambah.',
  loadFailed: 'Gagal memuat data',
  transactionDeleted: 'Transaksi dihapus',
  undo: 'URUNGKAN',
  recordTransaction: 'Catat Transaksi',
  daily: 'Harian',
  weekly: 'Mingguan',
  monthly: 'Bulanan',
  yearly: 'Tahunan',
  editTransaction: 'Edit Transaksi',
  amountCaps: 'NOMINAL',
  tapToTypeAmount: 'Ketuk untuk mengetik nominal',
  category: 'Kategori',
  paymentMethod: 'Metode Pembayaran',
  noteOptional: 'Catatan (opsional)',
  noteHistoryCaps: 'RIWAYAT CATATAN',
  deleteTransactionQuestion: 'Hapus transaksi ini?',
  deleteIrreversible: 'Data yang sudah dihapus tidak bisa dipulihkan.',
  transactionSaved: 'Transaksi tersimpan!',
  transactionUpdated: 'Transaksi diperbarui!',
  thousandUnit: 'ribu',
  millionUnit: 'juta',
  billionsUnit: 'miliaran',
  monthlyBudget: 'Anggaran Bulanan',
  used: 'Terpakai',
  budget: 'Anggaran',
  setBudget: 'Atur',
  remainingPrefix: 'Sisa',
  overBudgetPrefix: 'Lebih',
  overBudgetSuffix: 'dari anggaran!',
  budgetForPrefix: 'Anggaran',
  clearToDeleteBudget: 'Kosongkan / isi 0 untuk menghapus anggaran.',
  backupData: 'Backup Data',
  exportBackup: 'Export Backup',
  importBackup: 'Import Backup',
  importQuestion: 'Import backup?',
  importWarning:
      'Data transaksi dan anggaran di HP ini akan diganti dengan isi file backup.',
  backupImported: 'Backup berhasil di-import.',
  backupActionFailed: 'Aksi backup gagal. Coba lagi ya.',
  backupExplain:
      'Export membuat file JSON berisi transaksi, anggaran, dan status onboarding. Import akan memulihkan data dari file itu di perangkat baru.',
  safeToSwitchPhone: 'Pindah HP jadi aman',
  backupFileDesc: 'File backup data DilRecord Money.',
  backupShareTitle: 'Backup DilRecord Money',
  preparingBackup: 'Menyiapkan cadangan data…',
  savingDailyBackup: 'Menyimpan cadangan harian…',
  restoringBackup: 'Memulihkan cadangan data…',
  skip: 'Lewati',
  next: 'Lanjut',
  startNow: 'Mulai Sekarang',
  slide1Title: 'Catat Setiap Rupiah',
  slide1Body:
      'Rekam pemasukan & pengeluaranmu secepat mengetik pesan. Nggak ada lagi uang yang hilang tanpa jejak.',
  slide2Title: 'Lihat Ke Mana Uangmu Pergi',
  slide2Body:
      'Grafik warna-warni yang gampang dibaca. Tahu persis kategori mana yang paling bikin dompet tipis.',
  slide3Title: 'Capai Target Menabung',
  slide3Body:
      'Pasang target, kejar setiap hari, dan rayakan saat tercapai. Menabung jadi terasa seperti main game.',
  catFood: 'Makan & Minum',
  catTransport: 'Transport',
  catShopping: 'Belanja',
  catBills: 'Tagihan',
  catEntertainment: 'Hiburan',
  catHealth: 'Kesehatan',
  catEducation: 'Pendidikan',
  catSports: 'Olahraga',
  catVape: 'Vape',
  catOther: 'Lainnya',
  catSalary: 'Gaji',
  catBonus: 'Bonus',
  catBusiness: 'Usaha',
  catGift: 'Hadiah',
  catRefund: 'Pengembalian Dana',
  catFreelance: 'Freelance',
  walletCash: 'Tunai',
  walletBank: 'Bank',
  walletEwallet: 'E-Wallet',
  months: [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'Mei',
    'Jun',
    'Jul',
    'Agu',
    'Sep',
    'Okt',
    'Nov',
    'Des',
  ],
  monthsFull: [
    'Januari',
    'Februari',
    'Maret',
    'April',
    'Mei',
    'Juni',
    'Juli',
    'Agustus',
    'September',
    'Oktober',
    'November',
    'Desember',
  ],
  days: ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'],
  today: 'Hari ini',
  yesterday: 'Kemarin',
);

// ── English ──────────────────────────────────────────────────────────────────

const AppStrings _enStrings = AppStrings(
  appTagline: 'Your money-tracking buddy',
  cancel: 'Cancel',
  save: 'Save',
  delete: 'Delete',
  update: 'Update',
  done: 'Done',
  choose: 'Choose',
  settings: 'Settings',
  language: 'Language',
  appearance: 'Appearance',
  themeSystem: 'Follow System',
  themeLight: 'Light',
  themeDark: 'Dark',
  totalBalance: 'Total Balance',
  income: 'Income',
  expense: 'Expense',
  transactions: 'Transactions',
  recordsCount: 'records',
  noTransactionsTitle: 'No transactions yet',
  noTransactionsBody:
      'No transactions in this period.\nTap "Record Transaction" to add one.',
  loadFailed: 'Failed to load data',
  transactionDeleted: 'Transaction deleted',
  undo: 'UNDO',
  recordTransaction: 'Record Transaction',
  daily: 'Daily',
  weekly: 'Weekly',
  monthly: 'Monthly',
  yearly: 'Yearly',
  editTransaction: 'Edit Transaction',
  amountCaps: 'AMOUNT',
  tapToTypeAmount: 'Tap to type the amount',
  category: 'Category',
  paymentMethod: 'Payment Method',
  noteOptional: 'Note (optional)',
  noteHistoryCaps: 'NOTE HISTORY',
  deleteTransactionQuestion: 'Delete this transaction?',
  deleteIrreversible: 'Deleted data cannot be recovered.',
  transactionSaved: 'Transaction saved!',
  transactionUpdated: 'Transaction updated!',
  thousandUnit: 'thousand',
  millionUnit: 'million',
  billionsUnit: 'billions',
  monthlyBudget: 'Monthly Budget',
  used: 'Used',
  budget: 'Budget',
  setBudget: 'Set',
  remainingPrefix: 'Remaining',
  overBudgetPrefix: 'Over by',
  overBudgetSuffix: 'from budget!',
  budgetForPrefix: 'Budget for',
  clearToDeleteBudget: 'Leave empty / enter 0 to remove the budget.',
  backupData: 'Data Backup',
  exportBackup: 'Export Backup',
  importBackup: 'Import Backup',
  importQuestion: 'Import backup?',
  importWarning:
      'Transactions and budgets on this phone will be replaced with the backup file contents.',
  backupImported: 'Backup imported successfully.',
  backupActionFailed: 'Backup action failed. Please try again.',
  backupExplain:
      'Export creates a JSON file with your transactions, budgets, and onboarding status. Import restores data from that file on a new device.',
  safeToSwitchPhone: 'Switching phones made safe',
  backupFileDesc: 'DilRecord Money data backup file.',
  backupShareTitle: 'DilRecord Money Backup',
  preparingBackup: 'Preparing backup…',
  savingDailyBackup: 'Saving daily backup…',
  restoringBackup: 'Restoring backup…',
  skip: 'Skip',
  next: 'Next',
  startNow: 'Start Now',
  slide1Title: 'Track Every Cent',
  slide1Body:
      'Log your income and expenses as fast as sending a text. No more money disappearing without a trace.',
  slide2Title: 'See Where Your Money Goes',
  slide2Body:
      'Easy-to-read charts. Know exactly which category is draining your wallet.',
  slide3Title: 'Reach Your Savings Goal',
  slide3Body:
      'Set a target, chase it daily, and celebrate when you hit it. Saving feels like playing a game.',
  catFood: 'Food & Drink',
  catTransport: 'Transport',
  catShopping: 'Shopping',
  catBills: 'Bills',
  catEntertainment: 'Entertainment',
  catHealth: 'Health',
  catEducation: 'Education',
  catSports: 'Sports',
  catVape: 'Vape',
  catOther: 'Other',
  catSalary: 'Salary',
  catBonus: 'Bonus',
  catBusiness: 'Business',
  catGift: 'Gift',
  catRefund: 'Refund',
  catFreelance: 'Freelance',
  walletCash: 'Cash',
  walletBank: 'Bank',
  walletEwallet: 'E-Wallet',
  months: [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ],
  monthsFull: [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ],
  days: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'],
  today: 'Today',
  yesterday: 'Yesterday',
);

// ── 中文 (Simplified Chinese) ────────────────────────────────────────────────

const AppStrings _zhStrings = AppStrings(
  appTagline: '你的记账好帮手',
  cancel: '取消',
  save: '保存',
  delete: '删除',
  update: '更新',
  done: '完成',
  choose: '选择',
  settings: '设置',
  language: '语言',
  appearance: '外观',
  themeSystem: '跟随系统',
  themeLight: '浅色',
  themeDark: '深色',
  totalBalance: '总余额',
  income: '收入',
  expense: '支出',
  transactions: '交易',
  recordsCount: '条记录',
  noTransactionsTitle: '还没有交易记录',
  noTransactionsBody: '该时间段还没有交易。\n点击“记一笔”来添加。',
  loadFailed: '数据加载失败',
  transactionDeleted: '交易已删除',
  undo: '撤销',
  recordTransaction: '记一笔',
  daily: '每日',
  weekly: '每周',
  monthly: '每月',
  yearly: '每年',
  editTransaction: '编辑交易',
  amountCaps: '金额',
  tapToTypeAmount: '点击输入金额',
  category: '分类',
  paymentMethod: '支付方式',
  noteOptional: '备注（可选）',
  noteHistoryCaps: '备注历史',
  deleteTransactionQuestion: '要删除这笔交易吗？',
  deleteIrreversible: '删除后的数据无法恢复。',
  transactionSaved: '交易已保存！',
  transactionUpdated: '交易已更新！',
  thousandUnit: '千',
  millionUnit: '百万',
  billionsUnit: '十亿以上',
  monthlyBudget: '月度预算',
  used: '已用',
  budget: '预算',
  setBudget: '设置',
  remainingPrefix: '剩余',
  overBudgetPrefix: '超出',
  overBudgetSuffix: '预算！',
  budgetForPrefix: '预算：',
  clearToDeleteBudget: '留空或填 0 即可删除预算。',
  backupData: '数据备份',
  exportBackup: '导出备份',
  importBackup: '导入备份',
  importQuestion: '导入备份？',
  importWarning: '本机的交易和预算数据将被备份文件的内容替换。',
  backupImported: '备份导入成功。',
  backupActionFailed: '备份操作失败，请重试。',
  backupExplain: '导出会生成一个包含交易、预算和引导状态的 JSON 文件。导入可在新设备上恢复这些数据。',
  safeToSwitchPhone: '换手机也不怕',
  backupFileDesc: 'DilRecord Money 数据备份文件。',
  backupShareTitle: 'DilRecord Money 备份',
  preparingBackup: '正在准备备份…',
  savingDailyBackup: '正在保存每日备份…',
  restoringBackup: '正在恢复备份…',
  skip: '跳过',
  next: '下一步',
  startNow: '立即开始',
  slide1Title: '每一分钱都记下',
  slide1Body: '记录收入和支出，像发消息一样快。再也不会有钱不知不觉地消失。',
  slide2Title: '看清钱花在哪儿',
  slide2Body: '易读的图表，让你清楚知道哪个分类最耗钱。',
  slide3Title: '达成储蓄目标',
  slide3Body: '设定目标，每天坚持，达成时好好庆祝。存钱就像玩游戏一样。',
  catFood: '餐饮',
  catTransport: '交通',
  catShopping: '购物',
  catBills: '账单',
  catEntertainment: '娱乐',
  catHealth: '健康',
  catEducation: '教育',
  catSports: '运动',
  catVape: '电子烟',
  catOther: '其他',
  catSalary: '工资',
  catBonus: '奖金',
  catBusiness: '生意',
  catGift: '礼金',
  catRefund: '退款',
  catFreelance: '自由职业',
  walletCash: '现金',
  walletBank: '银行',
  walletEwallet: '电子钱包',
  months: [
    '1月',
    '2月',
    '3月',
    '4月',
    '5月',
    '6月',
    '7月',
    '8月',
    '9月',
    '10月',
    '11月',
    '12月',
  ],
  monthsFull: [
    '一月',
    '二月',
    '三月',
    '四月',
    '五月',
    '六月',
    '七月',
    '八月',
    '九月',
    '十月',
    '十一月',
    '十二月',
  ],
  days: ['周一', '周二', '周三', '周四', '周五', '周六', '周日'],
  today: '今天',
  yesterday: '昨天',
);

// ── 日本語 (Japanese) ────────────────────────────────────────────────────────

const AppStrings _jaStrings = AppStrings(
  appTagline: 'あなたの家計簿パートナー',
  cancel: 'キャンセル',
  save: '保存',
  delete: '削除',
  update: '更新',
  done: '完了',
  choose: '選択',
  settings: '設定',
  language: '言語',
  appearance: '表示',
  themeSystem: 'システムに合わせる',
  themeLight: 'ライト',
  themeDark: 'ダーク',
  totalBalance: '残高合計',
  income: '収入',
  expense: '支出',
  transactions: '取引',
  recordsCount: '件',
  noTransactionsTitle: '取引がまだありません',
  noTransactionsBody: 'この期間の取引はまだありません。\n「記録する」をタップして追加してください。',
  loadFailed: 'データの読み込みに失敗しました',
  transactionDeleted: '取引を削除しました',
  undo: '元に戻す',
  recordTransaction: '記録する',
  daily: '日別',
  weekly: '週別',
  monthly: '月別',
  yearly: '年別',
  editTransaction: '取引を編集',
  amountCaps: '金額',
  tapToTypeAmount: 'タップして金額を入力',
  category: 'カテゴリー',
  paymentMethod: '支払い方法',
  noteOptional: 'メモ（任意）',
  noteHistoryCaps: 'メモ履歴',
  deleteTransactionQuestion: 'この取引を削除しますか？',
  deleteIrreversible: '削除したデータは復元できません。',
  transactionSaved: '取引を保存しました！',
  transactionUpdated: '取引を更新しました！',
  thousandUnit: '千',
  millionUnit: '百万',
  billionsUnit: '十億以上',
  monthlyBudget: '月間予算',
  used: '使用済み',
  budget: '予算',
  setBudget: '設定',
  remainingPrefix: '残り',
  overBudgetPrefix: '予算より',
  overBudgetSuffix: '超過！',
  budgetForPrefix: '予算：',
  clearToDeleteBudget: '空欄または 0 で予算を削除します。',
  backupData: 'データのバックアップ',
  exportBackup: 'バックアップを書き出す',
  importBackup: 'バックアップを読み込む',
  importQuestion: 'バックアップを読み込みますか？',
  importWarning: 'この端末の取引と予算のデータは、バックアップファイルの内容で置き換えられます。',
  backupImported: 'バックアップを読み込みました。',
  backupActionFailed: 'バックアップ処理に失敗しました。もう一度お試しください。',
  backupExplain:
      '書き出すと、取引・予算・オンボーディング状態を含む JSON ファイルが作成されます。読み込むと、新しい端末でそのデータを復元できます。',
  safeToSwitchPhone: '端末の乗り換えも安心',
  backupFileDesc: 'DilRecord Money のデータバックアップファイル。',
  backupShareTitle: 'DilRecord Money バックアップ',
  preparingBackup: 'バックアップを準備中…',
  savingDailyBackup: '毎日のバックアップを保存中…',
  restoringBackup: 'バックアップを復元中…',
  skip: 'スキップ',
  next: '次へ',
  startNow: 'はじめる',
  slide1Title: '一円単位で記録',
  slide1Body: 'メッセージを送るくらいの速さで収支を記録。お金が理由もなく消えることはもうありません。',
  slide2Title: 'お金の行き先が見える',
  slide2Body: '読みやすいグラフで、どのカテゴリーが一番出費しているかが一目でわかります。',
  slide3Title: '貯金目標を達成',
  slide3Body: '目標を決めて毎日追いかけ、達成したら思いきり祝いましょう。貯金がゲームのように楽しくなります。',
  catFood: '飲食',
  catTransport: '交通',
  catShopping: '買い物',
  catBills: '請求・支払い',
  catEntertainment: '娯楽',
  catHealth: '健康',
  catEducation: '教育',
  catSports: 'スポーツ',
  catVape: '電子タバコ',
  catOther: 'その他',
  catSalary: '給料',
  catBonus: 'ボーナス',
  catBusiness: '事業',
  catGift: '贈り物',
  catRefund: '返金',
  catFreelance: 'フリーランス',
  walletCash: '現金',
  walletBank: '銀行',
  walletEwallet: '電子マネー',
  months: [
    '1月',
    '2月',
    '3月',
    '4月',
    '5月',
    '6月',
    '7月',
    '8月',
    '9月',
    '10月',
    '11月',
    '12月',
  ],
  monthsFull: [
    '1月',
    '2月',
    '3月',
    '4月',
    '5月',
    '6月',
    '7月',
    '8月',
    '9月',
    '10月',
    '11月',
    '12月',
  ],
  days: ['月', '火', '水', '木', '金', '土', '日'],
  today: '今日',
  yesterday: '昨日',
);
