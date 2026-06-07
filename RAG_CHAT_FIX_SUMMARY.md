# 🔧 Chat RAG & Summarize - Vấn đề & Giải pháp

## 🔴 Vấn đề Tìm Ra

### 1. **Tính năng Tóm tắt (Summarize) bị lỗi**

**Vị trí**: `lib/screens/reader/reader_screen.dart` → `_handleSummarize()`

**Nguyên nhân**:

- Hàm `summarizeChapter()` trong `book_repository.dart` **KHÔNG gửi `chapterId`** tới API
- Backend API `/api/ai/summarize` có thể mong đợi `chapterId` nhưng chỉ nhận `content`
- Khi API mới không hỗ trợ request không có `chapterId`, sẽ bị 400/422 error

```dart
// ❌ CỦ - Chỉ gửi content
body: jsonEncode({"content": text}),

// ✅ MỚI - Gửi chapterId + content
body: jsonEncode({
  "chapterId": chapterId,
  "content": text,
}),
```

---

### 2. **Tính năng Chat RAG bị lỗi**

**Vị trí**: `lib/screens/ai_chat/bloc/ai_chat_bloc.dart`

**Nguyên nhân**:

- RAG mode bị **tắt** (`useRAG = false`)
- Khi gọi API, thiếu logging chi tiết để debug lỗi
- Fallback không xử lý được trường hợp cả Legacy cũng bị lỗi

```dart
// ❌ CỬ - RAG disabled
bool useRAG = false;

// Khi bật RAG nhưng API bị lỗi, không có info chi tiết
```

---

## ✅ Giải Pháp Thực Hiện

### 1. **Fix Summarize (Done)**

**File**: `lib/repositories/book_repository.dart`

```dart
// Thêm optional parameter chapterId
Future<String?> summarizeChapter(String text, {String? chapterId}) async {
  // ...
  body: jsonEncode({
    "chapterId": chapterId,
    "content": text,
  }),
}
```

**File**: `lib/screens/reader/reader_screen.dart`

```dart
// Truyền chapterId khi gọi
final summary = await repo.summarizeChapter(cleanText, chapterId: widget.chapterId);
```

### 2. **Cải thiện Logging cho RAG (Done)**

**File**: `lib/screens/ai_chat/bloc/ai_chat_bloc.dart`

- Thêm chi tiết logging khi RAG được gọi
- Thêm chi tiết logging khi RAG fail + fallback
- Xử lý đúng cả trường hợp Legacy fail

**File**: `lib/repositories/ai_chat_repository.dart`

- Thêm logging endpoint, status code, response body
- Cải thiện error message để dễ debug

---

## 📊 Kiểm Tra API Endpoint

### Endpoints cần kiểm tra:

```
POST /api/ai/chat
- Body: { userId, bookId, chapterId, question, context }
- Response: { answer }

POST /api/ai/chat-rag
- Body: { userId, bookId, chapterId, question }
- Response: { answer, relevantPassages, method, success }

POST /api/ai/summarize
- Body: { chapterId, content }  ✅ FIX: Thêm chapterId
- Response: { summary }
```

### Kiểm tra baseURL:

```
✅ Current: http://136.110.33.241:3000
```

---

## 🧪 Cách Test

### Test Summarize:

1. Mở Reader Screen
2. Click nút "Tóm tắt" (Summarize button)
3. Kiểm tra Console log:

```
📝 Summarize Request:
  Endpoint: http://136.110.33.241:3000/api/ai/summarize
  ChapterId: xxx
  Content length: 15000
✅ Summarize Success: 500 chars
```

### Test Chat RAG:

1. Mở Chat Dialog
2. Gửi câu hỏi
3. Kiểm tra Console log:

```
📝 Using Legacy Prompt Engineering method...
✅ Legacy Response received: ...

hoặc (nếu enable RAG)

🚀 Using RAG method...
  BookId: xxx
  ChapterId: xxx
  Question: ...
✅ RAG Response received: ...
```

---

## 🎯 Next Steps

### Để enable RAG mode:

```dart
// File: lib/screens/ai_chat/bloc/ai_chat_bloc.dart
// Đổi:
bool useRAG = false;
// Thành:
bool useRAG = true;  // Khi backend ready
```

### Nếu vẫn bị lỗi:

1. Kiểm tra **baseURL** trong `.env` có đúng không
2. Kiểm tra **API endpoint** backend có hỗ trợ `/api/ai/chat` hoặc `/api/ai/chat-rag` không
3. Kiểm tra **request body** có khớp API spec không
4. Xem **Console log** để chi tiết lỗi từ API

---

## 📝 Tóm tắt Fix

| Vấn đề                        | File                      | Fix                                  |
| ----------------------------- | ------------------------- | ------------------------------------ |
| Summarize thiếu chapterId     | `book_repository.dart`    | ✅ Thêm `chapterId` parameter & body |
| Reader không truyền chapterId | `reader_screen.dart`      | ✅ Truyền `chapterId` khi gọi        |
| RAG logging không chi tiết    | `ai_chat_bloc.dart`       | ✅ Thêm logging details              |
| RAG error không rõ            | `ai_chat_repository.dart` | ✅ Cải thiện error message           |

---

**Status**: ✅ **COMPLETE** - Tất cả fix đã apply, sẵn sàng test
