import '../../models/models.dart';

/// Lightweight, hand-rolled localization for the app.
class AppStrings {
  final String locale; // 'en' or 'id'
  const AppStrings(this.locale);

  bool get _id => locale == 'id';
  String _t(String en, String id) => _id ? id : en;

  // Bottom navigation
  String get navDashboard => _t('Dashboard', 'Dasbor');
  String get navInvoices => _t('Invoices', 'Invoice');
  String get navCustomers => _t('Customers', 'Pelanggan');
  String get navSettings => _t('Settings', 'Pengaturan');

  // Dashboard
  String get manageInvoicesEasily =>
      _t('Manage your invoices easily', 'Kelola invoice Anda dengan mudah');
  String get totalRevenue => _t('Total Revenue', 'Total Pendapatan');
  String get comparedToLastMonth =>
      _t('Compared to last month', 'Dibanding bulan lalu');
  String get paid => _t('Paid', 'Lunas');
  String get pending => _t('Pending', 'Tertunda');
  String get overdue => _t('Overdue', 'Jatuh Tempo');
  String get recentInvoices => _t('Recent Invoices', 'Invoice Terbaru');
  String get seeAll => _t('See All', 'Lihat Semua');
  String get noInvoicesYetTitle => _t('No invoices yet', 'Belum ada invoice');
  String get noInvoicesYetMessage => _t(
      'Create your first invoice and start tracking your payments.',
      'Buat invoice pertama Anda dan mulai lacak pembayaran.');

  // Settings
  String get settingsTitle => _t('Settings', 'Pengaturan');
  String get manageBusinessPreferences => _t(
      'Manage your business & app preferences',
      'Kelola bisnis & preferensi aplikasi');
  String get sectionBusiness => _t('Business', 'Bisnis');
  String get sectionPreferences => _t('Preferences', 'Preferensi');
  String get sectionAppearance => _t('Appearance', 'Tampilan');
  String get sectionData => _t('Data', 'Data');
  String get businessProfile => _t('Business Profile', 'Profil Bisnis');
  String get invoiceSettings => _t('Invoice Settings', 'Pengaturan Invoice');
  String get paymentMethods => _t('Payment Methods', 'Metode Pembayaran');
  String get taxSettings => _t('Tax Settings', 'Pengaturan Pajak');
  String get currency => _t('Currency', 'Mata Uang');
  String get invoiceTemplate => _t('Invoice Template', 'Template Invoice');
  String get language => _t('Language', 'Bahasa');
  String get transactionRecap => _t('Transaction Recap', 'Rekap Transaksi');
  String get notifications => _t('Notifications', 'Notifikasi');
  String get light => _t('Light', 'Terang');
  String get dark => _t('Dark', 'Gelap');
  String get system => _t('System', 'Sistem');
  String get backupRestore => _t('Backup & Restore', 'Cadangkan & Pulihkan');
  String get about => _t('About', 'Tentang');
  String get tapToEditBusinessProfile =>
      _t('Tap to edit business profile', 'Ketuk untuk edit profil bisnis');

  // Backup & Restore sheet
  String get backupRestoreDescription => _t(
      'Export a backup file you can keep safe, or restore your data from one.',
      'Ekspor file cadangan yang bisa Anda simpan, atau pulihkan data Anda dari file cadangan.');
  String get exportBackup => _t('Export Backup', 'Ekspor Cadangan');
  String get exportBackupDescription => _t(
      'Save all invoices, customers, and settings to a file.',
      'Simpan semua invoice, pelanggan, dan pengaturan ke sebuah file.');
  String get restoreBackup => _t('Restore from Backup', 'Pulihkan dari Cadangan');
  String get restoreBackupDescription => _t(
      'Replace all current data with a backup file.',
      'Ganti semua data saat ini dengan file cadangan.');
  String get restoreAction => _t('Restore', 'Pulihkan');
  String get confirmRestoreTitle => _t('Restore this backup?', 'Pulihkan cadangan ini?');
  String confirmRestoreMessage(int customerCount, int invoiceCount) => _t(
      'This replaces everything on this device with $customerCount customers and $invoiceCount invoices from the backup file. This cannot be undone.',
      'Ini akan mengganti semua data di perangkat ini dengan $customerCount pelanggan dan $invoiceCount invoice dari file cadangan. Tindakan ini tidak dapat dibatalkan.');
  String get restoreSuccess => _t('Data restored', 'Data berhasil dipulihkan');
  String get backupExportFailed =>
      _t("Couldn't create the backup file", 'Gagal membuat file cadangan');
  String get backupInvalidJson =>
      _t('That file is not a valid backup file.', 'File tersebut bukan file cadangan yang valid.');
  String get backupUnsupportedVersion => _t(
      'This backup was made by a newer version of the app.',
      'Cadangan ini dibuat oleh versi aplikasi yang lebih baru.');
  String get backupUnrecognized =>
      _t("This doesn't look like an Invoicely backup.", 'Ini bukan file cadangan Invoicely.');

  // Language picker sheet
  String get selectLanguage => _t('Select Language', 'Pilih Bahasa');
  String get selectLanguageDescription =>
      _t('Choose the app display language.', 'Pilih bahasa tampilan aplikasi.');
  String get languageEnglish => 'English';
  String get languageIndonesian => 'Indonesia';

  // Transaction Recap screen
  String get recapSubtitle => _t('Summary of your transactions by period',
      'Ringkasan transaksi berdasarkan periode');
  String get periodToday => _t('Today', 'Hari Ini');
  String get periodWeek => _t('This Week', 'Minggu Ini');
  String get periodMonth => _t('This Month', 'Bulan Ini');
  String get periodYear => _t('This Year', 'Tahun Ini');
  String get periodAll => _t('All Time', 'Semua Waktu');
  String get totalInvoices => _t('Total Invoices', 'Total Invoice');
  String get totalCollected => _t('Collected', 'Terkumpul');
  String get noTransactionsTitle =>
      _t('No transactions', 'Tidak ada transaksi');
  String get noTransactionsMessage => _t(
      'No invoices were issued in this period.',
      'Tidak ada invoice yang dibuat pada periode ini.');
  String get revenueOverview => _t('Revenue Overview', 'Ringkasan Pendapatan');

  // Invoices list
  String get invoicesTitle => _t('Invoices', 'Invoice');
  String get manageAllInvoices =>
      _t('Manage all your invoices', 'Kelola semua invoice Anda');
  String get searchInvoiceHint => _t('Search invoice...', 'Cari invoice...');
  String get filterAll => _t('All', 'Semua');
  String get filterUnpaid => _t('Unpaid', 'Belum Lunas');
  String get filterDraft => _t('Draft', 'Draf');
  String get noInvoicesFoundTitle =>
      _t('No invoices found', 'Invoice tidak ditemukan');
  String get noInvoicesFoundMessage => _t(
      'Try a different search term or filter.',
      'Coba kata kunci pencarian atau filter lain.');
  String get invoiceDeleted => _t('Invoice deleted', 'Invoice dihapus');
  String get undo => _t('UNDO', 'URUNGKAN');
  String get walkInCustomer => _t('Walk-in Customer', 'Pelanggan Umum');

  // Customers list
  String get customersSubtitle =>
      _t('Everyone you do business with', 'Semua rekan bisnis Anda');
  String get searchCustomerHint =>
      _t('Search customer...', 'Cari pelanggan...');
  String get noCustomersYetTitle =>
      _t('No customers yet', 'Belum ada pelanggan');
  String get noCustomersFoundTitle =>
      _t('No customers found', 'Pelanggan tidak ditemukan');
  String get addFirstCustomerMessage => _t(
      'Add your first customer to start creating invoices.',
      'Tambahkan pelanggan pertama Anda untuk mulai membuat invoice.');
  String get tryDifferentSearchTerm =>
      _t('Try a different search term.', 'Coba kata kunci pencarian lain.');
  String get addCustomer => _t('Add Customer', 'Tambah Pelanggan');
  String get customerAdded => _t('Customer added', 'Pelanggan ditambahkan');
  String invoicesCount(int n) => _t('$n invoices', '$n invoice');

  // Customer detail
  String get customerDetailTitle => _t('Customer Detail', 'Detail Pelanggan');
  String get activeStatus => _t('Active', 'Aktif');
  String get phoneLabel => _t('Phone', 'Telepon');
  String get emailLabel => _t('Email', 'Email');
  String get addressLabel => _t('Address', 'Alamat');
  String get totalInvoiceLabel => _t('Total Invoice', 'Total Invoice');
  String get customerNotFound =>
      _t('Customer not found', 'Pelanggan tidak ditemukan');

  // Add/Edit customer sheet
  String get editCustomerTitle => _t('Edit Customer', 'Edit Pelanggan');
  String get newCustomerTitle => _t('New Customer', 'Pelanggan Baru');
  String get fullNameLabel => _t('Full Name', 'Nama Lengkap');
  String get fullNameHint => _t('e.g. Mas Pra', 'cth. Mas Pra');
  String get phoneNumberLabel => _t('Phone Number', 'Nomor Telepon');
  String get addressHint => _t('Street, city...', 'Jalan, kota...');
  String get saveChanges => _t('Save Changes', 'Simpan Perubahan');
  String get deleteCustomer => _t('Delete Customer', 'Hapus Pelanggan');
  String get cancel => _t('Cancel', 'Batal');
  String get delete => _t('Delete', 'Hapus');
  String confirmDeleteCustomerTitle(String name) =>
      _t('Delete $name?', 'Hapus $name?');
  String get confirmDeleteCustomerMessage => _t(
      'Their invoices will be kept, but no longer linked to a customer. This action cannot be undone.',
      'Invoice mereka akan tetap disimpan, namun tidak lagi terhubung dengan pelanggan ini. Tindakan ini tidak dapat dibatalkan.');

  // Products & Services
  String get productsAndServices => _t('Products & Services', 'Produk & Jasa');
  String get productsSubtitle => _t(
      'Save prices so items don\'t need retyping', 'Simpan harga agar item tidak perlu diketik ulang');
  String get searchProductHint => _t('Search product...', 'Cari produk...');
  String get noProductsYetTitle => _t('No products yet', 'Belum ada produk');
  String get noProductsFoundTitle =>
      _t('No products found', 'Produk tidak ditemukan');
  String get addFirstProductMessage => _t(
      'Add your products or services to reuse their prices on invoices.',
      'Tambahkan produk atau jasa Anda untuk memakai ulang harganya di invoice.');
  String get addProduct => _t('Add Product', 'Tambah Produk');
  String get productAdded => _t('Product added', 'Produk ditambahkan');
  String get editProductTitle => _t('Edit Product', 'Edit Produk');
  String get newProductTitle => _t('New Product', 'Produk Baru');
  String get deleteProduct => _t('Delete Product', 'Hapus Produk');
  String confirmDeleteProductTitle(String name) => _t('Delete $name?', 'Hapus $name?');
  String get confirmDeleteProductMessage => _t(
      'This only removes it from your saved catalog — invoices that already use it are unaffected.',
      'Ini hanya menghapusnya dari katalog tersimpan — invoice yang sudah memakainya tidak terpengaruh.');
  String get chooseFromCatalog => _t('Choose from catalog', 'Pilih dari katalog');
  String get selectProduct => _t('Select Product', 'Pilih Produk');
  String get newProduct => _t('+ New Product', '+ Produk Baru');
  String get noProductsFoundInSearch =>
      _t('No products found', 'Produk tidak ditemukan');
  String get orEnterManually =>
      _t('or enter item details manually below', 'atau isi detail item secara manual di bawah');

  // Create/Edit invoice screen
  String get editInvoiceTitle => _t('Edit Invoice', 'Edit Invoice');
  String get createInvoiceTitle => _t('Create Invoice', 'Buat Invoice');
  String get save => _t('Save', 'Simpan');
  String get saving => _t('Saving...', 'Menyimpan...');
  String get saveAndPreview => _t('Save & Preview', 'Simpan & Pratinjau');
  String get done => _t('Done', 'Selesai');
  String get clear => _t('Clear', 'Hapus');
  String get newCustomer => _t('+ New Customer', '+ Pelanggan Baru');
  String get selectCustomerFirst => _t('Please select a customer first',
      'Silakan pilih pelanggan terlebih dahulu');
  String get addAtLeastOneItem =>
      _t('Add at least one item', 'Tambahkan minimal satu item');
  String get invoiceSaved => _t('Invoice saved', 'Invoice disimpan');
  String get invoiceNumberLabel => _t('Invoice #', 'No. Invoice');
  String get dueOnReceipt => _t('Due on Receipt', 'Jatuh Tempo Saat Diterima');
  String get dueDate => _t('Due Date', 'Tanggal Jatuh Tempo');
  String get invoiceDate => _t('Invoice Date', 'Tanggal Invoice');
  String get businessInfo => _t('Business Info', 'Info Bisnis');
  String toCustomer(String name) => _t('To: $name', 'Kepada: $name');
  String get toSelectCustomer =>
      _t('To: Select Customer', 'Kepada: Pilih Pelanggan');
  String get addItem => _t('Add Item', 'Tambah Item');
  String itemsCount(int n) => _t('$n Item${n > 1 ? 's' : ''}', '$n Item');
  String get subtotal => _t('Subtotal', 'Subtotal');
  String get discount => _t('Discount', 'Diskon');
  String get tax => _t('Tax', 'Pajak');
  String get shipping => _t('Shipping', 'Pengiriman');
  String get total => _t('Total', 'Total');
  String get payments => _t('Payments', 'Pembayaran');
  String get balanceDue => _t('Balance Due', 'Sisa Tagihan');
  String get addPhoto => _t('Add Photo', 'Tambah Foto');
  String get paymentInstruction =>
      _t('Payment Instruction', 'Instruksi Pembayaran');
  String get signature => _t('Signature', 'Tanda Tangan');
  String get approvedByCustomer => _t('Approved by', 'Disetujui oleh');
  String get markedAsPaid => _t('Marked as Paid', 'Ditandai Lunas');
  String get markPaid => _t('Mark Paid', 'Tandai Lunas');
  String get paymentMethod => _t('Payment Method', 'Metode Pembayaran');
  String get currentSignature => _t('Current: ', 'Saat ini: ');
  String get selectCustomer => _t('Select Customer', 'Pilih Pelanggan');
  String get noCustomersFoundInSearch =>
      _t('No customers found', 'Pelanggan tidak ditemukan');
  String get amountPrefix => _t('Rp ', 'Rp ');
  String get poReferenceNumber =>
      _t('PO / Reference Number', 'Nomor PO / Referensi');
  String get approverName => _t('Approver name', 'Nama penyetuju');
  String get noteHint => _t('Add a note for your customer...',
      'Tambahkan catatan untuk pelanggan Anda...');
  String get defaultThankYouNote => _t('Thank you for shopping with us!',
      'Terima kasih telah berbelanja bersama kami!');
  String get drawBelowToReplace => _t(
      'Draw below to replace the current signature',
      'Gambar di bawah untuk mengganti tanda tangan saat ini');
  String get drawBelow => _t('Draw below', 'Gambar di bawah ini');
  String paymentMethodLabel(String method) {
    switch (method) {
      case 'Bank Transfer':
        return _t('Bank Transfer', 'Transfer Bank');
      case 'Cash':
        return _t('Cash', 'Tunai');
      case 'QRIS':
        return 'QRIS';
      case 'E-Wallet':
        return _t('E-Wallet', 'E-Wallet');
      default:
        return method;
    }
  }

  // Add item sheet
  String get editItemTitle => _t('Edit Item', 'Edit Item');
  String get addItemTitle => _t('Add Item', 'Tambah Item');
  String get productNameLabel => _t('Product Name', 'Nama Produk');
  String get productNameHint =>
      _t('e.g. Waffle Tinggi Ori', 'cth. Waffle Tinggi Ori');
  String get priceLabel => _t('Price', 'Harga');
  String get quantityLabel => _t('Quantity', 'Jumlah');
  String get saveItemChanges => _t('Save Changes', 'Simpan Perubahan');
  String defaultTaxHint(String percent) =>
      _t('0 (default $percent%)', '0 (bawaan $percent%)');

  // Invoice items screen
  String get itemsTitle => _t('Items', 'Item');
  String get noItemsYetTitle => _t('No items yet', 'Belum ada item');
  String get addItemsMessage => _t(
      'Add the products or services for this invoice.',
      'Tambahkan produk atau jasa untuk invoice ini.');

  // Invoice paper (printable preview + PDF)
  String moreItemsSuffix(int n) => _t('+$n more', '+$n lainnya');
  String invoicePaperTitle(String number) =>
      _t('INVOICE $number', 'INVOICE $number');
  String refLine(String poNumber) => _t('Ref: $poNumber', 'Ref: $poNumber');
  String get billTo => _t('BILL TO', 'DITAGIHKAN KEPADA');
  String get onReceiptShort => _t('On Receipt', 'Saat Diterima');
  String paidOn(String date) => _t('PAID ($date)', 'DIBAYAR ($date)');
  String get scanQrisToPay =>
      _t('Scan the QRIS code to pay.', 'Pindai kode QRIS untuk membayar.');
  String get paymentDueCash => _t('Payment due in cash upon receipt.',
      'Pembayaran tunai saat barang diterima.');
  String get notesLabel => _t('NOTES', 'CATATAN');
  String get attachmentLabel => _t('ATTACHMENT', 'LAMPIRAN');
  String get approvalLabel => _t('APPROVAL', 'PERSETUJUAN');
  String approvedBy(String name) =>
      _t('Approved by $name', 'Disetujui oleh $name');
  String get pendingApproval => _t('Pending approval', 'Menunggu persetujuan');
  String get customerFallback => _t('customer', 'pelanggan');
  String get invoiceDueLabel => _t('INVOICE DUE', 'JATUH TEMPO INVOICE');
  String get dueOnReceiptLong =>
      _t('Due On Receipt', 'Jatuh Tempo Saat Diterima');
  String get descriptionLabel => _t('DESCRIPTION', 'DESKRIPSI');
  String get rateLabel => _t('RATE', 'HARGA');
  String get qtyLabel => _t('QTY', 'JML');
  String qrisMid(String id) => _t('MID: $id', 'MID: $id');

  // Invoice detail screen
  String get invoiceNotFound =>
      _t('Invoice not found', 'Invoice tidak ditemukan');
  String get duplicateTooltip => _t('Duplicate', 'Duplikat');
  String get editTooltip => _t('Edit', 'Edit');
  String invoiceDuplicatedAs(String number) => _t(
      'Invoice duplicated as $number', 'Invoice diduplikasi menjadi $number');
  String issuedOn(String date) => _t('Issued $date', 'Diterbitkan $date');
  String get updateStatus => _t('Update Status', 'Ubah Status');
  String get deleteInvoice => _t('Delete Invoice', 'Hapus Invoice');
  String get preview => _t('Preview', 'Pratinjau');
  String confirmDeleteInvoiceTitle(String number) =>
      _t('Delete $number?', 'Hapus $number?');
  String get confirmDeleteInvoiceMessage => _t(
      'This action cannot be undone from here.',
      'Tindakan ini tidak dapat dibatalkan dari sini.');

  // Invoice preview / PDF export
  String get invoiceSentSuccessfully =>
      _t('Invoice sent successfully', 'Invoice berhasil dikirim');
  String get send => _t('Send', 'Kirim');
  String get sending => _t('Sending...', 'Mengirim...');
  String get sent => _t('Sent!', 'Terkirim!');
  String get preparingInvoice =>
      _t('Preparing invoice...', 'Menyiapkan invoice...');
  String get generatingPdf => _t('Generating PDF...', 'Membuat PDF...');
  String get pdfReady => _t('PDF ready', 'PDF siap');
  String get openPdf => _t('Open PDF', 'Buka PDF');
  String get share => _t('Share', 'Bagikan');
  String get close => _t('Close', 'Tutup');
  String get sendInvoiceTitle => _t('Send Invoice', 'Kirim Invoice');
  String get shareVia => _t('Share via', 'Bagikan melalui');
  String get otherApps => _t('Other Apps', 'Aplikasi Lain');
  String shareTextMessage(String number, String total) => _t(
      'Here is your invoice $number, total $total.',
      'Berikut invoice Anda $number, total $total.');
  String shareInvoiceText(String number) =>
      _t('Invoice $number', 'Invoice $number');
  String get copyInvoiceLink => _t('Copy Invoice Link', 'Salin Tautan Invoice');
  String get invoiceLinkCopied =>
      _t('Invoice link copied', 'Tautan invoice disalin');
  String get copyInvoiceNumber =>
      _t('Copy Invoice Number', 'Salin Nomor Invoice');
  String get invoiceNumberCopied =>
      _t('Invoice number copied', 'Nomor invoice disalin');

  // Invoice status badge
  String statusLabel(InvoiceStatus status) {
    switch (status) {
      case InvoiceStatus.draft:
        return _t('DRAFT', 'DRAF');
      case InvoiceStatus.unpaid:
        return _t('UNPAID', 'BELUM LUNAS');
      case InvoiceStatus.paid:
        return _t('PAID', 'LUNAS');
      case InvoiceStatus.overdue:
        return _t('OVERDUE', 'JATUH TEMPO');
      case InvoiceStatus.partial:
        return _t('PARTIAL', 'SEBAGIAN');
    }
  }
}
