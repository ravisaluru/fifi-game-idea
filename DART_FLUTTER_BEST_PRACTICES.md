# Flutter & Dart Architecture and Code Quality Guidelines

This document outlines the standard operating rules, design principles, and code quality expectations for all models, widgets, and services in **Fifi's World Adventures**. These principles guarantee a clean, high-performance, and easily maintainable codebase (KISS, SRP, DRY).

---

## 1. Core Architectural Pillars

### 🚀 KISS (Keep It Simple, Stupid)
- Keep solutions simple. Do not over-engineer.
- Prefer explicit Dart features (e.g. standard loops, clean async/await, native Flutter widgets) over complex libraries unless absolutely required.
- **Example**: Direct direct Color values distributed evenly in HSL color space rather than complex mapping lists or nested state mechanisms.

### 🧩 SRP (Single Responsibility Principle)
- **Widgets/Screens** should only be responsible for rendering UI and forwarding user interaction events. They must NOT contain raw business logic or direct persistence code.
- **Models/Services** (e.g. `GameState`, `MultiplayerService`) should be the single source of truth for logic, state mutation, network interactions, and calculations.
- **Example**: `VictoryPopup` is strictly a presentation overlay, while `GameState` calculates currency rewards and completes the world session.

### ♻️ DRY (Don't Repeat Yourself)
- Identify common widgets and layouts (e.g., confirmation dialogs, back buttons, progress indicators) and extract them into `/lib/widgets/` for global reuse.
- **Example**: Rather than having copy-pasted back-to-menu overlays on 7 separate world canvases, we created a single importable `BackToMenuButton` widget.

---

## 2. Strong Typing & Compile-Time Safety
All files must adhere to the rules configured in `analysis_options.yaml`:

### 🔒 Strict Casts & Type Inference
* Always declare explicit type arguments for generic structures (e.g., `StreamSubscription<Map<String, dynamic>>`, `Future<void>`, `List<Offset>`). Never declare raw types like `StreamSubscription?`.
* Always declare return types on public methods, helper callbacks, and getters.
* Use `const` constructors and widgets wherever possible to enable compile-time rendering reuse, saving CPU cycles on web viewports.

---

## 3. Memory & Resource Management
Memory leaks are unacceptable, especially on Flutter Web. Always clean up after yourself:

- **Stateful Widget Disposals**:
  * Always call `.dispose()` on `AnimationController`s, `TextEditingController`s, `ScrollController`s, and `TabController`s in your State's `dispose()` lifecycle.
  * Always cancel active `Timer`s (`_timer?.cancel()`) and `StreamSubscription`s (`_subscription?.cancel()`) to prevent resource exhaustion.
- **Safe Controller Disposals on Rebuilds**:
  * When replacing controllers dynamically (such as during level-up bubble resets), **setState** to rebuild the widget tree first (unmounting the old widgets) before calling `.dispose()` on the old controllers. This prevents disposed animations from throwing silent exceptions.

---

## 4. Encapsulation & Object-Oriented Principles
* **State Immutability**: Prefer declaring variables as `final` wherever possible (`final List<Offset> positions`).
* **Private Internals**: Encapsulate class variables with private modifiers (`_variable`) and expose public changes via clean setters/getters or state notifier triggers.
* **Declarative UI**: Let Flutter do the rendering. Use `AnimatedBuilder` for canvas animations rather than triggering heavy `setState` loops inside tick timers.
