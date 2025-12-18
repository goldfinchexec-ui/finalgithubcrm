# Goldfinch CRM (Flutter Edition) — Architecture

## MVP (connected “brain”)
- Entities:
  - User (required baseline model)
  - Driver
  - Client
  - LedgerTransaction (central ledger)
- Relationships:
  - Driver Invoice → creates LedgerTransaction(type=EXPENSE, category=DRIVER_PAYOUT, relatedDriverId)
  - Client Invoice → creates LedgerTransaction(type=INCOME, category=CLIENT_INVOICE, relatedClientId)
  - Receipt Vault → filtered view of transactions where attachments is not empty

## Data layer (local-first)
- Storage: SharedPreferences (JSON lists). No backend connected.
- Services (lib/services):
  - UserService: current staff profile
  - DriverService: CRUD + seed sample data
  - ClientService: CRUD + seed sample data
  - TransactionService: CRUD + derived queries (month filter, range filter, receipt vault)
  - AttachmentService: pick file, create data URL, open/view/download

> Supabase: when ready, open the Supabase panel in Dreamflow and complete setup; then we can swap services to Supabase with the same models.

## State management
- Riverpod (flutter_riverpod)
- Providers:
  - currentUserProvider
  - driversProvider
  - clientsProvider
  - transactionsProvider
  - uiShellProvider (sidebar collapsed, filters)

## Routing
- go_router with a shell layout:
  - /dashboard
  - /drivers
  - /driver-invoices
  - /clients
  - /client-invoices
  - /general-income
  - /general-expenses
  - /receipt-vault

## UI system (Shadcn-inspired)
- App shell: Row layout, left sidebar (250px) with collapse mode (70px), right content.
- Tokens in theme.dart:
  - Background Slate-50 (#F8FAFC)
  - Sidebar Slate-900 (#0F172A)
  - Borders Slate-200 (#E2E8F0)
  - Radius 8
  - Inter via GoogleFonts
- Components (lib/ui):
  - AppShellScaffold, SidebarNav
  - ShadCard, ShadButton (primary/secondary/ghost), ShadTextField, ShadDropdown
  - StatusBadge, StaffChip
  - TableHeaderRow + TableDataRow (Row-based, flex template)
  - ModalDialogFrame

## Screens
- Dashboard: month totals (income/expense/net)
- Drivers: searchable table + add/edit/delete modal
- Driver Invoices: month filter + range picker modal + add/edit invoice modal (attachments)
- Clients: searchable table + add/edit/delete modal
- Client Invoices: month filter + add/edit invoice modal
- General Income/Expenses: add/edit items with frequency; expenses support attachments
- Receipt Vault: table view, sortable by date, view/download actions

## Non-functional
- Invisible scrollbars via custom ScrollBehavior
- Currency formatting: en_GB, £
- Accessibility: 48px targets, semantics labels for icon buttons

## Debug
- Run `flutter pub get` + `dart analyze` at the end and fix all issues.
