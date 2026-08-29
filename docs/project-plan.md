# 🥊 RefBot — Workshop Plan

## Core Product

The entire application revolves around one simple flow:

**Humans debate → AI analyzes → Audience votes**

There are **3 phases**.

---

# Phase 1 — Human Debate

### Goal

Create a simple space where **Team A and Team B can conduct a structured debate**.

### How it works

1. The moderator creates a debate topic.
2. Team A and Team B are shown the topic.
3. Team A gives its opening argument.
4. Team B gives its opening argument.
5. Teams alternate turns.
6. Each argument is added to the debate history.
7. Both teams can see everything that has previously been said.
8. The moderator ends the debate when the discussion is complete.

### Debate screen

The main screen contains:

* Debate topic
* Team A
* Team B
* Current turn
* Debate history
* Argument submission area

### Debate history

Arguments appear chronologically:

**Team A — Round 1**
Argument...

**Team B — Round 1**
Argument...

**Team A — Round 2**
Argument...

**Team B — Round 2**
Argument...

The history remains visible throughout the debate.

### End state

At the end of Phase 1, the application is a functioning **human-vs-human debate platform**.

---

# Phase 2 — AI Referee

### Goal

Add an AI referee that watches the debate and provides analysis.

The AI **does not participate in the debate**.

It only observes what the teams say.

### How it works

After each argument:

1. A team submits an argument.
2. The argument becomes part of the debate history.
3. The AI referee analyzes the argument.
4. Its analysis appears alongside that argument.
5. The debate continues.

### The referee looks for only 3 things

#### ✓ Claims / Facts

The referee identifies factual claims and assesses whether they appear supported.

#### ⚠ Missing Context

The referee points out important context that may be missing from the argument.

#### 🚨 Logical Fallacies

The referee identifies obvious logical fallacies in the argument when present.

### Example

**Team A**

> "Social media is clearly destroying society because everyone knows it's harmful."

**AI Referee**

🚨 **Logical fallacy:** Appeal to common belief

⚠ **Missing context:** The argument does not establish what "destroying society" means or provide evidence for the claim.

---

### Important behavior

The referee analyzes **both teams equally**.

It does not decide who wins.

It does not argue with either team.

It simply provides an independent analysis after each turn.

### End state

The debate now contains two layers:

**Human discussion**

and

**AI analysis of the discussion**

---

# Phase 3 — Audience Voting

### Goal

Allow the audience to decide which team they believe performed better.

### How it works

1. The debate continues normally.
2. The AI referee continues analyzing the arguments.
3. The moderator ends the debate.
4. The audience is asked:

> **"Which team won the debate?"**

5. Each audience member chooses:

   * Team A
   * Team B
6. Votes are collected.
7. The results are displayed.

### Voting screen

```text
WHO WON THE DEBATE?

        TEAM A       TEAM B

          62%          38%

       124 votes     76 votes
```

The audience can see the result after voting.

---

# Final Product Flow

The complete experience is:

```text
                    DEBATE TOPIC
                         │
                         ▼
                 ┌───────────────┐
                 │   TEAM A      │
                 │   ARGUMENT    │
                 └───────┬───────┘
                         │
                         ▼
                 ┌───────────────┐
                 │   TEAM B      │
                 │   ARGUMENT    │
                 └───────┬───────┘
                         │
                         ▼
                  ┌─────────────┐
                  │ AI REFEREE  │
                  │             │
                  │ Claims      │
                  │ Context     │
                  │ Fallacies   │
                  └──────┬──────┘
                         │
                         ▼
                    NEXT ROUND
                         │
                         ▼
                    NEXT ROUND
                         │
                         ▼
                  DEBATE ENDS
                         │
                         ▼
                  AUDIENCE VOTES
                         │
                         ▼
                   FINAL RESULT
```
