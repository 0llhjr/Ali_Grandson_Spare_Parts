# API Update — Conversation Context

## What Changed

The chatbot now remembers previous Q&A turns within a session. Follow-up questions like *"what about the price?"* or *"do you have that in red?"* will work correctly without repeating context.

---

## Changes to `/chat`

**Request — add `session_id` field:**
```json
{
  "question": "Do you have brake pads?",
  "session_id": "uuid-from-previous-response"
}
```
- First message of a new chat → omit `session_id` or send `null`
- Every follow-up → send the `session_id` returned from the previous response

**Response — now includes `session_id`:**
```json
{
  "status": "answered",
  "answer": "Yes, we stock several brake pad brands...",
  "session_id": "a1b2c3d4-uuid"
}
```

---

## Changes to `/chat/respond`

Response now also includes `session_id` — save it the same way:
```json
{
  "status": "answered",
  "answer": "Brembo brake pads are OMR 18.000, currently in stock.",
  "session_id": "a1b2c3d4-uuid"
}
```

---

## Integration Pattern

```js
let sessionId = null; // reset this when user starts a new chat

async function askChatbot(question) {
  const res = await fetch(`${API_BASE}/chat`, {
    method: "POST",
    headers: { "Content-Type": "application/json", "X-API-Key": API_KEY },
    body: JSON.stringify({ question, session_id: sessionId }),
  });
  const data = await res.json();
  sessionId = data.session_id; // always save back
  return data;
}
```

**To start a new conversation** (e.g. user taps "New Chat"): set `sessionId = null`.

---

## Notes

- Session expires after **30 minutes** of inactivity — after that, a new session starts automatically even if you send the old `session_id`
- The server keeps the last **3 Q&A pairs** as context — older turns are dropped automatically
- No changes to error handling or the `/chat/respond` request body
