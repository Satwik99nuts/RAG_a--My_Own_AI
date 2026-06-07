# VectorDB — from scratch in C++

I built this to actually understand how vector databases work internally, not just use them as a black box. Every layer of it — the graph, the distance math, the RAG pipeline — is written by hand in C++, no external ML libraries.

If you've ever used Pinecone or Chroma and wondered "how does this thing find similar text so fast?", this project is the answer.

---

## What's inside

Three search algorithms running side-by-side so you can compare them live:

- **HNSW** — the real one, the same graph-based algorithm production databases use
- **KD-Tree** — fast on low dimensions, falls apart at 768D (and that's kind of the point)
- **Brute Force** — the dumb baseline that checks everything

Three distance metrics: cosine, euclidean, manhattan.

A full RAG pipeline: paste your notes → Ollama embeds them → HNSW indexes them → ask questions → local LLM answers using your docs as context. All offline, nothing sent to any API.

There's also a live PCA scatter plot in the browser that shows vector clusters forming in real time as you search.

---

## How the RAG pipeline works

```
your text
    ↓
nomic-embed-text (via Ollama)   →  converts to 768D vector
    ↓
HNSW index (C++)                →  finds nearest chunks
    ↓
llama3.2 (via Ollama)           →  reads chunks, writes answer
    ↓
answer
```

The upper HNSW layers act like a highway — you skip across the dataset quickly, then zoom into the right neighborhood at layer 0. That's how it stays O(log N) instead of O(N).

---

## Setup (Windows)

You need three things: a C++ compiler, Git, and Ollama.

### 1. Install MSYS2 (gets you g++)

Download from [msys2.org](https://www.msys2.org), install to the default path, then open the MSYS2 UCRT64 terminal and run:

```bash
pacman -Syu
pacman -S mingw-w64-ucrt-x86_64-gcc
```

Then add `C:\msys64\ucrt64\bin` to your Windows PATH (Win+R → `sysdm.cpl` → Advanced → Environment Variables → Path → New).

Open a fresh PowerShell and check it worked:
```powershell
g++ --version
```

### 2. Install Git

[git-scm.com/download/win](https://git-scm.com/download/win) — default settings are fine.

### 3. Install Ollama + pull the models

Download from [ollama.com](https://ollama.com), then:

```powershell
ollama pull nomic-embed-text   # ~274 MB, the embedding model
ollama pull llama3.2           # ~2 GB, the LLM
```

8GB RAM minimum. Both models together use about 3GB.

### 4. Clone and compile

```powershell
git clone https://github.com/Satwik99nuts/RAG_a.git
cd RAG_a
```

Or just use the `run.bat` script I included — it compiles and starts the server in one shot:

```powershell
./run.bat
```

If you want to do it manually:
```powershell
g++ -std=c++17 -O2 main.cpp -o db -lws2_32
./db
```

Then open `http://localhost:1729` in your browser.

---

## Using it

**Search tab** — type anything (`binary tree`, `sushi`, `basketball`) and hit search. Switch between HNSW, KD-Tree, and Brute Force and watch the latency difference. Hit "Compare All" to benchmark them against each other on the same query.

**Documents tab** — paste in any text (lecture notes, articles, whatever). It splits long text into 250-word overlapping chunks, embeds each one via Ollama, and stores them in the HNSW index.

**Ask AI tab** — type a question. It embeds your question, retrieves the 3 most relevant chunks from your documents, and feeds them to llama3.2 to generate an answer. Click the context chips to see exactly which chunks it used.

---

## API

Server runs at `http://localhost:1729`.

```
GET  /search?v=...&k=5&metric=cosine&algo=hnsw   → KNN search
GET  /benchmark?v=...&k=5&metric=cosine           → compare all 3 algos
GET  /hnsw-info                                   → graph layer stats
GET  /items                                       → list all demo vectors
POST /insert                                      → add a demo vector
DELETE /delete/:id

POST /doc/insert   {"title":"...","text":"..."}   → embed + store
POST /doc/ask      {"question":"...","k":3}       → full RAG answer
GET  /doc/list
DELETE /doc/delete/:id
GET  /status                                      → ollama status
```

Quick test:
```powershell
curl "http://localhost:1729/search?v=0.9,0.8,0.7,0.6,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1&k=3&metric=cosine&algo=hnsw"
```

---

## Files

```
RAG_a/
├── main.cpp     → everything: HNSW, KD-Tree, BruteForce, HTTP server, RAG
├── httplib.h    → single-header C++ HTTP library (cpp-httplib)
├── index.html   → the frontend
├── run.bat      → compile + run in one command
└── README.md
```

---

## Troubleshooting

**Ollama shows OFFLINE** — run `ollama serve` in a separate terminal.

**g++ not found** — PATH isn't set. Add `C:\msys64\ucrt64\bin` and open a fresh terminal.

**LLM is slow** — totally normal on a laptop CPU, llama3.2 takes 10–30s. Switch to the 1B model if you want faster responses:
```powershell
ollama pull llama3.2:1b
```
Then change `genModel` in `main.cpp` to `"llama3.2:1b"` and recompile.

**Port already in use** — find and kill whatever's on 1729:
```powershell
netstat -ano | findstr 1729
taskkill /PID <pid> /F
```

---

## Author

Built by **Satwik_Shivam**

© 2026 Satwik_Shivam. All rights reserved.
