---
alwaysApply: false
description: 通用设计模式
---

# Common Patterns

## Skeleton Projects

When implementing new functionality:

1. **Search for battle-tested skeleton projects**
2. **Use parallel agents to evaluate options:**
   - Security assessment
   - Extensibility analysis
   - Relevance scoring
   - Implementation planning
3. **Clone best match as foundation**
4. **Iterate within proven structure**

## Design Patterns

### Repository Pattern

Encapsulate data access behind a consistent interface.
Abstracts data sources (remote/local) from business logic.

- Consistent interface for data access
- Easy to swap data sources
- Simplifies testing with mocks
- Clear separation of concerns

> **Dart/Flutter 具体实现** → 详见 [dart/patterns.md](dart/patterns.md)

### API Response Format

Use a consistent envelope for all API responses:

```dart
class ApiResponse<T> {
  final bool success;
  final T? data;
  final String? error;
  final PaginationMetadata? pagination;

  const ApiResponse({
    required this.success,
    this.data,
    this.error,
    this.pagination,
  });

  factory ApiResponse.success(T data, {PaginationMetadata? pagination}) {
    return ApiResponse(
      success: true,
      data: data,
      pagination: pagination,
    );
  }

  factory ApiResponse.error(String message) {
    return ApiResponse(
      success: false,
      error: message,
    );
  }
}

class PaginationMetadata {
  final int total;
  final int page;
  final int limit;
  final int totalPages;

  const PaginationMetadata({
    required this.total,
    required this.page,
    required this.limit,
    required this.totalPages,
  });
}
```

**Benefits:**
- Consistent client handling
- Clear success/error states
- Built-in pagination support
- Easy to extend

### State Management Patterns

See language-specific patterns:
- Dart/Flutter: `dart/patterns.md` (Riverpod, BLoC)
- TypeScript: `typescript/patterns.md` (Redux, Zustand)
- Python: `python/patterns.md` (Services, Context)

## Architectural Patterns

### Clean Architecture

```
┌─────────────────┐
│   Presentation  │  (UI, Widgets, Views)
├─────────────────┤
│     Domain      │  (Business Logic, Use Cases)
├─────────────────┤
│      Data       │  (Repositories, Data Sources)
└─────────────────┘

Dependency Rule: Inner layers cannot depend on outer layers
```

### Layered Architecture

```
┌─────────────────┐
│   Controllers   │  (HTTP handlers, route handlers)
├─────────────────┤
│     Services    │  (Business logic, orchestration)
├─────────────────┤
│  Repositories   │  (Data access abstraction)
├─────────────────┤
│   Data Access   │  (Database, external APIs)
└─────────────────┘
```

## See Also

- Language-specific patterns: `dart/patterns.md`
- State management: `RIVERPOD.md`
- Architecture decisions: Check project ADRs
