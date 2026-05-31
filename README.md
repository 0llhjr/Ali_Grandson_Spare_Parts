# Ali Grandsons Spare Parts - Flutter Migration

## 🏗 Project Architecture

This project follows a **Feature-First** industry-standard architecture. The structure is designed to separate business logic, UI, and data layers to ensure maximum scalability and maintainability.

### Directory Structure

- `lib/main.dart`: The main entry point that initializes the app and global services.
- `lib/src/app.dart`: The root `MaterialApp` widget where themes and routing are configured.
- `lib/src/core/`: Global essentials used by the entire app.
  - `database/`: Local SQLite persistence logic.
  - `session/`: Persistent user/admin authentication state.
  - `theme/`: Global styling, colors, and visual constants.
- `lib/src/shared/`: Logic and widgets that are reused across multiple features.
  - `services/`: Reusable logic like Email or Cloud services.
- `lib/src/features/`: The heart of the app, divided by business domain.
  - Each feature (e.g., `auth`, `catalog`, `orders`) contains:
    - `data/`: Local/Remote data sources and repositories.
    - `presentation/`: UI components divided into `pages` and `widgets`.

## 📜 Import Conventions

Always use **Absolute Package Imports** instead of relative paths.
- ✅ `import 'package:alis_grandson_app/src/core/theme/app_colors.dart';`
- ❌ `import '../../core/theme/app_colors.dart';`

This prevents broken links when moving files and is the standard for professional Dart development.

## 🚀 Onboarding for New Developers

1. **Adding a Feature**: Create a new subfolder in `lib/src/features/` naming it after the business domain (e.g., `search`). Add `presentation/pages` for the screens.
2. **Naming**: Use `lowercase_with_underscores.dart` for all file names.
3. **Single Responsibility**: Each file should ideally contain only one public class. If a page has a complex widget, move it into a `presentation/widgets` subfolder.
4. **Logic**: Database changes must be performed in `src/core/database/database_helper.dart` to maintain a single source of truth.
