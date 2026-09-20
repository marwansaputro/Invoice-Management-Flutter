# Invoicely — Create. Send. Get Paid.

A modern, premium Invoice Management & Generator mobile app built with
Flutter + Dart, Material 3, Riverpod, and Hive (local, offline-first
storage — no backend, no login).

This document is the map for anyone new to the codebase: how it's laid
out, why it's laid out that way, and the conventions to follow when
extending it. Read this before making structural changes.

## Getting started

```bash
flutter pub get
flutter run
```

The app seeds itself with realistic dummy data (5 customers, 8 invoices)
on first launch, so every screen is populated immediately. The product
catalog starts empty — it's a newer feature dummy data doesn't cover yet.

## Stack

- **Flutter (stable) + Dart**, Material 3
- **State management:** `flutter_riverpod` (StateNotifier-based repositories,
  see [State management](#state-management))
- **Local database:** Hive (hand-written `TypeAdapter`s — no code
  generation step required, so `flutter pub get` is all you need)
- **PDF generation:** `pdf` + `printing`
- **Sharing / export:** `share_plus`, `file_picker` (backup restore)
- **Media:** `image_picker`, `image`, `signature` (signature capture),
  `qr_flutter` + `barcode` (QRIS)
- **Typography:** `google_fonts` (Plus Jakarta Sans)
- **No** code generation, no `build_runner`, no cloud SDK, no auth — this
  is a deliberate choice to keep the project buildable with just
  `flutter pub get`. See [Known limitations](#known-limitations-by-design)
  before reaching for one of these.

## Architecture overview

Data flows in one direction, top to bottom; UI never touches Hive directly:

```
Hive boxes (on-device storage)
        │
        ▼
AppDatabase            — owns box handles + two convenience singletons
(lib/data/database)      (AppDatabase.business, AppDatabase.settings)
        │
        ▼
Repositories            — StateNotifier<List<T>> wrapping a box; every
(lib/data/repositories)   mutation writes to Hive THEN republishes state
        │
        ▼
Riverpod providers      — *RepositoryProvider, exposed for `ref.watch`/`ref.read`
        │
        ▼
Feature screens/widgets — features/*, watch providers, never import Hive
(lib/features, core/widgets)
```

Two things sit outside that chain because they need the full dataset,
not a single repository's slice:

- **`BackupService`** (`lib/data/backup/backup_service.dart`) reads/writes
  every box directly to build/restore a single JSON file.
- **`AppStrings`** (`lib/core/localization/app_strings.dart`) is a pure
  function of a locale string — it never touches Hive.

## Project structure

```
lib/
├── main.dart                        # Hive init → seed dummy data → runApp
├── core/
│   ├── theme/app_theme.dart         # AppColors, Material 3 light/dark ThemeData
│   ├── animations/app_motion.dart   # AppDurations, AppCurves, AnimatedEntry,
│   │                                 #   PressableScale, SlideFadeRoute, showScaleFadeDialog
│   ├── localization/app_strings.dart# Hand-rolled i18n — see below
│   ├── widgets/
│   │   ├── widgets.dart             # AppButton, AppCard, StatusBadge, MoneyText,
│   │   │                             #   AnimatedNumber, EmptyState, LoadingSkeleton,
│   │   │                             #   AppSnackbar, AppTextField, CollapsibleSearchBar,
│   │   │                             #   showAppBottomSheet / AppBottomSheetShell
│   │   ├── invoice_widgets.dart     # InvoiceListCard, InvoiceItemRow, TotalSummary,
│   │   │                             #   InvoicePaper (the on-screen "printable" layout)
│   │   └── glass_backdrop.dart      # Blurred background blobs behind every screen
│   └── utils/
│       ├── formatters.dart          # AppFormatters: money(), moneyCompact(), dates
│       └── pdf_generator.dart       # Builds the actual PDF — mirrors InvoicePaper by hand
├── models/models.dart               # Customer, Invoice, InvoiceItem, BusinessProfile,
│                                     #   InvoiceSettingsModel, Product + their Hive adapters
├── data/
│   ├── database/app_database.dart   # Hive.init, adapter registration, box handles
│   ├── repositories/repositories.dart # All StateNotifiers + providers (see below)
│   ├── backup/backup_service.dart   # Export/import ALL boxes as one JSON file
│   └── dummy_data.dart              # First-launch sample customers/invoices
├── features/
│   ├── dashboard/                   # Home tab: revenue summary, recent invoices
│   ├── invoices/                    # Invoices tab: list + detail
│   ├── invoice_create/              # Create/edit invoice, add item, item list
│   ├── invoice_preview/             # "Printable paper" preview, PDF export, share
│   ├── customers/                   # Customers tab: list + detail + add/edit sheet
│   ├── products/                    # Product/service catalog: list + add/edit sheet
│   ├── reports/                     # Transaction Recap: period stats + bar chart
│   └── settings/                    # Business profile, invoice/tax/currency settings,
│                                     #   language, theme, Backup & Restore, About
└── routes/root_shell.dart           # 4-tab bottom nav (Dashboard/Invoices/Customers/
                                      #   Settings) + the floating "Create Invoice" FAB
```

Each `features/<name>/` folder owns everything specific to that screen:
the screen itself, any bottom sheets it opens, and small private widgets
used only there. Widgets reused across *multiple* features live in
`core/widgets/` instead (e.g. `InvoiceListCard` appears on the Invoices
list, Dashboard, Customer detail, and Transaction Recap).

## State management

Every piece of persisted data follows the same shape. Using
`ProductRepository` as the simplest complete example
(`lib/data/repositories/repositories.dart`):

```dart
class ProductRepository extends StateNotifier<List<Product>> {
  ProductRepository() : super(_sorted());          // 1. seed state from Hive on creation

  static List<Product> _sorted() =>
      AppDatabase.productsBox.values.toList()..sort(...);

  void _refresh() => state = _sorted();             // 2. re-read + republish after any write

  Product add({...}) {
    final product = Product(...);
    AppDatabase.productsBox.put(product.id, product); // 3. write to Hive FIRST
    _refresh();                                       // 4. then update Riverpod state
    return product;
  }

  void reload() => _refresh();                        // 5. public hook for bulk restore
}

final productRepositoryProvider =
    StateNotifierProvider<ProductRepository, List<Product>>((ref) => ProductRepository());
```

Rules that fall out of this pattern — follow them for any new
persisted entity:

- **Hive write, then `_refresh()`.** Never mutate `state` directly; always
  re-derive it from the box so Hive stays the single source of truth.
- **Every repository exposes a public `reload()`** that just calls
  `_refresh()`. It exists solely so `BackupService`'s restore flow (which
  writes to Hive boxes directly, bypassing the repository) can force
  every screen watching that provider to pick up the new data. If you
  add a repository, add `reload()` and wire it into
  `settings_screen.dart`'s `_restoreBackup()`.
- **Simple singletons** (`BusinessProfile`, `InvoiceSettingsModel`) don't
  get a list-based repository. They're read via `AppDatabase.business` /
  `AppDatabase.settings` (lazily created on first access) and mutated
  in place, then `.save()` (a `HiveObject` method) persists them. UI
  screens that show them just call `setState(() {})` after editing —
  see `_editBusinessProfile()` in `settings_screen.dart`. **Ignore
  `businessProfileProvider`** — it's dead code (defined, never watched
  anywhere); don't build new features on it expecting it to update on
  edits, since nothing ever writes to its state.
- **`themeModeProvider` / `localeProvider`** are `StateNotifierProvider<_,
  int|String>` — thin wrappers that mirror one field of
  `InvoiceSettingsModel` into a watchable value, since watching the whole
  settings singleton isn't possible (it's not read through a provider).
- **Derived data** (e.g. `dashboardStatsProvider`) is a plain `Provider`
  that watches a repository provider and computes from it — no separate
  storage, no repository needed.

## Persistence (Hive)

`lib/data/database/app_database.dart` opens one box per model and
registers one hand-written `TypeAdapter` per model in `models.dart` —
there's no `build_runner`/codegen step. Each adapter carries a fixed
`typeId` that **must stay unique and must never be reused**, even for a
deleted model (Hive uses it to disambiguate binary-encoded objects
already saved on users' devices):

| typeId | Model                  |
|-------:|-------------------------|
| 0      | `Customer`               |
| 1      | `InvoiceItem`             |
| 2      | `Invoice`                 |
| 3      | `BusinessProfile`         |
| 4      | `InvoiceSettingsModel`    |
| 5      | `Product`                 |

**Adding a new persisted model:** pick the next unused typeId, write the
model class + a `TypeAdapter` by hand (copy the `Product` one — it's the
shortest), register the adapter and open its box in `AppDatabase.init()`,
then add a repository (see above). Also add `toJson`/`fromJson` to the
model and wire it into `BackupService` (see below) — it's easy to forget
and the new box will silently be excluded from backups.

## Backup & Restore

`lib/data/backup/backup_service.dart` is the *only* way data leaves the
device — there's no cloud sync. It serializes every box to one versioned
JSON file (`{"version": 1, "business": {...}, "settings": {...},
"customers": [...], "invoices": [...], "products": [...]}`, with binary
fields like signatures/logos/photos as base64) and shares it via the OS
share sheet. Restore reverses this: pick a `.json` file, validate its
`version`, then **replace** every box's contents (destructive — the
Settings UI confirms with the user first, showing counts from the
parsed file).

If you add a new Hive box, you must:
1. Add `toJson`/`fromJson` to its model.
2. Add it to `BackupData`, `_buildPayload()`, `parse()`, and `restore()`
   in `backup_service.dart`.
3. Call its repository's `reload()` in `settings_screen.dart`'s
   `_restoreBackup()` after `BackupService.restore(data)` runs.

Skipping this doesn't break anything visibly — it just means that data
type quietly isn't backed up, which nobody will notice until they lose
it.

## Localization

`lib/core/localization/app_strings.dart` is a **hand-rolled i18n
system**, not `flutter_localizations`/ARB files — there are no `.arb`
files, no generated `AppLocalizations`, no `intl_utils`. `AppStrings` is
a plain class wrapping a `'en'`/`'id'` locale string, with one getter (or
method, for parameterized/pluralized text) per piece of UI copy:

```dart
class AppStrings {
  final String locale;
  const AppStrings(this.locale);
  bool get _id => locale == 'id';
  String _t(String en, String id) => _id ? id : en;

  String get invoicesTitle => _t('Invoices', 'Invoice');
  String invoicesCount(int n) => _t('$n invoices', '$n invoice');
}
```

`localeProvider` (in `repositories.dart`) holds the current locale,
persisted on `InvoiceSettingsModel.locale`. Every screen reads it the
same way:

```dart
final l10n = AppStrings(ref.watch(localeProvider));
...
Text(l10n.invoicesTitle)
```

**Adding UI text:** add a getter/method to `AppStrings` (English +
Indonesian), then use it via `l10n.yourGetter` — never a raw string
literal in a widget `Text(...)`. For a widget that isn't already a
`ConsumerWidget`/`ConsumerState` (i.e. can't `ref.watch`), convert it to
one rather than threading a `locale` string through constructors — that's
the pattern used throughout (e.g. `StatusBadge`, `InvoiceListCard`,
`TotalSummary`, `InvoicePaper` are all `ConsumerWidget` purely so they
can localize their own text).

One deliberate gap: **dates are not localized** — `AppFormatters` always
renders English month abbreviations (`"20 Sep 2026"`) regardless of
`locale`. This is pre-existing and consistent everywhere dates appear;
if you localize one date, localize the formatter, not the call site.

## UI conventions

- **Bottom sheets:** `showAppBottomSheet<T>(context, child: ...)` wraps
  content in the shared frosted-glass shell (`AppBottomSheetShell`). The
  sheet widget returns its result via `Navigator.pop(context, value)`;
  the caller awaits the sheet call and acts on the result — sheets never
  call repository methods themselves except via a passed-in `onDelete`
  callback (see `AddCustomerSheet`/`AddProductSheet`).
- **Confirm dialogs:** `showScaleFadeDialog<bool>(context, child: ...)`
  for anything destructive (delete, restore-overwrite). The dialog pops
  `true`/`false`; the caller performs the action. Follow
  `_ConfirmDeleteProductDialog` as the template — icon, title, message,
  Cancel (outline) + destructive action (`AppButtonStyleType.danger`).
- **Picker sheets** (customer picker, product picker) follow one shape:
  search bar, scrollable result list capped at `maxHeight: 300`, an empty
  state, and a trailing "+ New X" button that pops a sentinel string
  (`'NEW'`) for the caller to open the matching add-sheet. See
  `_ProductPickerSheet` in `add_item_sheet.dart` or `_CustomerPickerSheet`
  in `create_invoice_screen.dart`.
- **Snackbars:** `AppSnackbar.show(context, message: ..., icon: ...,
  color: ...)` — pass `AppColors.danger`/`.success`/`.warning` to match
  the action's severity; omit `color` for a neutral confirmation.
- **Animation:** wrap list items / entering content in `AnimatedEntry`
  (optionally staggered via `delay: Duration(milliseconds: 40 * i)`), and
  wrap tappable rows/cards in `PressableScale` for the press-down
  feedback used everywhere instead of `InkWell`. Use `AppDurations.*` /
  `AppCurves.*` instead of inventing new timing constants.
- **Navigation:** pushing a new screen (not a tab) uses
  `Navigator.of(context).push(SlideFadeRoute(page: ...))`, never the
  default `MaterialPageRoute`.
- **Naming:** widgets private to one file are prefixed `_` and live below
  the main screen class in the same file. A widget gets promoted to its
  own public file only once a second screen needs it (that's exactly why
  `AddCustomerSheet` and `AddProductSheet` are their own files instead of
  private classes inside their list screens).

## Worked example: adding a feature

The Product catalog (`lib/features/products/`) is the most recent
complete vertical slice and doubles as a template. Adding a similar
feature means, in order:

1. **Model + adapter** in `models.dart` (next unused `typeId`) with
   `toJson`/`fromJson`.
2. **Box** registered + opened in `AppDatabase.init()`.
3. **Repository + provider** in `repositories.dart`, with `reload()`.
4. **Backup integration** in `backup_service.dart` (see above).
5. **Screen(s)**: a list screen (`ProductsScreen`) and an add/edit sheet
   (`AddProductSheet`) with its own confirm-delete dialog, mirroring
   `CustomersScreen`/`AddCustomerSheet` almost line for line.
6. **AppStrings entries** for every string the new UI shows, English +
   Indonesian.
7. **Wire into navigation** — either a bottom-nav tab (`root_shell.dart`)
   or, for secondary features, a row in Settings pushed via
   `SlideFadeRoute` (see the "Products & Services" row in
   `settings_screen.dart`).
8. If the feature should be pickable from elsewhere (like products from
   the invoice item form), add a picker sheet following the "Picker
   sheets" convention above.

## Known limitations (by design)

These are intentional simplifications, not bugs — know them before
"fixing" something that's actually working as designed, and consider
them the natural next steps if extending the app:

- **No cloud sync, no auth.** Everything is on-device Hive storage.
  `BackupService`'s JSON export is the only way data leaves the device.
- **Tax and discount are flat amounts**, not percentages, at both the
  line-item and invoice level (`InvoiceItem.discount/tax`,
  `Invoice.discount/tax`). `InvoiceSettingsModel.defaultTaxPercent` is
  only a UI convenience that pre-fills the Tax field's hint text in
  `add_item_sheet.dart` — it is not applied automatically.
- **`amountPaid` is a single running total**, not a list of individual
  payments — there's no payment history/audit trail for partially-paid
  invoices.
- **No recurring invoices.** There's no frequency/interval field or
  scheduler anywhere.
- **`InvoiceSettingsModel.notificationsEnabled` is a dead field.** Its
  UI section is commented out in `settings_screen.dart` and nothing
  reads the flag — there's no local-notifications dependency wired up.
  `Invoice.dueDate` exists and is displayed, but nothing alerts on it.
- **Currency is one global setting**, not stored per invoice
  (`InvoiceSettingsModel.currencySymbol`). Most money display currently
  goes through `MoneyText`/`AppFormatters.money()` defaulting to `Rp`
  regardless of that setting — changing the currency picker doesn't
  retroactively (or consistently) change displayed amounts app-wide.
- **`InvoicePaper` (the on-screen printable widget) and `PdfGenerator`
  (the actual PDF) are two independent implementations kept in sync by
  hand.** There is no shared layout code between them. If you change one
  visually, mirror the change in the other or the PDF/preview will
  drift apart. This is the single easiest place to introduce a
  hard-to-notice bug.
- **`InvoiceStatus` doubles as both workflow state and payment badge**
  (`draft/unpaid/partial/paid/overdue`) — one enum instead of two, to
  keep the model simple.
- **Products have no relationship to invoice line items.** Picking a
  product from the catalog just copies its name/price into a freeform
  `InvoiceItem` at that moment — editing or deleting a product afterward
  never touches invoices that already used it.

## Testing / verifying changes

- `flutter analyze` before considering any change done — the project is
  currently clean (style-only `info`s like `withOpacity` deprecation
  warnings are pre-existing and fine to leave).
- There's no widget/unit test suite yet.
- For visually verifying UI changes without a device/emulator, this repo
  has `.claude/launch.json` configured to serve a `flutter build web`
  output for browser-based preview during development. That web build is
  a developer convenience only — the app is not shipped as a web app,
  and a few plugins (`path_provider`, `share_plus`, `file_picker`)
  behave differently or are inert on web, so file-export/share/restore
  flows should get a real pass on Android/iOS before you trust them.

## Fonts / icons

Uses Material Icons (bundled) and Google Fonts (fetched at runtime on
first launch, then cached) — no asset bundling required.
