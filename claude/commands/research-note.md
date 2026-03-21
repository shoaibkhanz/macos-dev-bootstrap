---
name: research-note
description: Create structured research notes for ML papers, articles, and technical topics in British English
---

## What I do

1. Create research note in `~/code/projects/obsidian/rememberme/Atlas/Papers/` folder
2. Use structured format for: summary, key insights, methodology, results, questions
3. Add relevant tags (research, ML, papers, transformers, RAG, etc.)
4. Link to related notes in the vault using `[[wiki-links]]`
5. Include source URL or citation if provided
6. Use British English throughout

## Template Structure

```markdown
---
type: Research
title: {Topic or Paper Title}
date: '{YYYY-MM-DD}'
tags: [research, {topic-tags}]
source: {URL or citation if provided}
---

# {Topic or Paper Title}

## Summary

{Brief overview of the paper/topic in 2-3 sentences}

## Key Insights

- {Main contribution or finding 1}
- {Main contribution or finding 2}
- {Main contribution or finding 3}

## Methodology

{How the research was conducted, architecture used, approach taken}

## Results

{Key findings, performance metrics, comparisons}

## Related Work

- [[Related Note 1]]
- [[Related Note 2]]

## Questions

- {Open questions or areas for further exploration}
- {Things to investigate}

## References

{URLs, citations, or links to papers}
```

## Filename Conventions

Use descriptive filenames:
- For papers: `{Paper Title}.md` (e.g., `Attention Is All You Need.md`)
- For topics: `{Topic Name}.md` (e.g., `RAG Architectures.md`)
- Use Title Case for readability
- Replace special characters with spaces or hyphens

## Tag Suggestions

Suggest relevant tags based on content:

**ML/AI Topics**:
- research, ML, papers, AI
- transformers, attention, BERT, GPT
- RAG, retrieval, embeddings
- fine-tuning, PEFT, LoRA, RLHF
- LLM, language-models
- computer-vision, NLP

**General Research**:
- theory, survey, benchmark
- datasets, evaluation
- optimization, training

## Linking to Existing Notes

Before creating the note:
1. Search vault for related topics
2. Identify notes to link in "Related Work" section
3. Common links:
   - `[[Build a Large Language Model]]` (book)
   - `[[Learning LLMs]]` (learning plan)
   - `[[Transformers]]`, `[[BERT]]`, `[[GPT]]` (concepts)
   - People: `[[Author Name]]` if they exist in Collections/People/

## British English Requirements

All content must use British English:
- "Analyse" not "analyze"
- "Optimise" not "optimize"
- "Realise" not "realize"
- "Whilst" (formal), "amongst"
- "Behaviour", "colour", "favour"
- "Centre", "metre"
- "Travelling", "modelling", "labelled"

## Examples

### Example 1: Research Paper

**User**: "Create research note for 'Attention Is All You Need'"

**Output**: `Atlas/Papers/Attention Is All You Need.md`

```markdown
---
type: Research
title: Attention Is All You Need
date: '2025-12-31'
tags: [research, papers, transformers, attention, NLP]
source: https://arxiv.org/abs/1706.03762
---

# Attention Is All You Need

## Summary

Introduces the Transformer architecture that relies entirely on self-attention mechanisms, dispensing with recurrence and convolutions. Achieves state-of-the-art results on machine translation tasks whilst being more parallelisable and requiring less time to train.

## Key Insights

- Self-attention allows modelling dependencies without regard to distance in sequences
- Multi-head attention enables the model to jointly attend to information from different representation subspaces
- Positional encoding is crucial for maintaining sequence order information
- Architecture is highly parallelisable compared to RNNs and LSTMs

## Methodology

- Encoder-decoder architecture with stacked self-attention and feed-forward layers
- Multi-head attention with 8 parallel attention layers
- Positional encoding using sine and cosine functions
- Trained on WMT 2014 English-German and English-French translation tasks

## Results

- BLEU score of 28.4 on WMT 2014 English-German translation
- BLEU score of 41.8 on English-French translation
- Training time significantly reduced compared to previous state-of-the-art

## Related Work

- [[Build a Large Language Model]]
- [[Transformers]]
- [[Learning LLMs]]

## Questions

- How does attention mechanism scale to very long sequences?
- What are the trade-offs between attention heads and model size?
- Can this architecture be adapted for other domains beyond NLP?

## References

- arXiv: https://arxiv.org/abs/1706.03762
- Authors: Vaswani et al., 2017
```

### Example 2: Technical Topic

**User**: "Create research note on RAG architectures"

**Output**: `Atlas/Papers/RAG Architectures.md`

```markdown
---
type: Research
title: RAG Architectures
date: '2025-12-31'
tags: [research, RAG, retrieval, LLM, embeddings]
---

# RAG Architectures

## Summary

Retrieval-Augmented Generation (RAG) combines large language models with external knowledge retrieval to improve factual accuracy and reduce hallucinations whilst maintaining the flexibility of generative models.

## Key Insights

- Separates parametric knowledge (in LLM weights) from non-parametric knowledge (retrieved documents)
- Enables updating knowledge without retraining the model
- Improves factual grounding and reduces hallucinations
- Allows for source attribution and verification

## Methodology

Core components:
1. **Encoder**: Converts documents into embeddings
2. **Retriever**: Finds relevant documents using similarity search
3. **Generator**: LLM that uses retrieved context to generate response

Common implementations:
- Dense Passage Retrieval (DPR)
- FAISS or ChromaDB for vector storage
- Bi-encoder architecture for efficient retrieval

## Results

Compared to pure generative models:
- Higher factual accuracy on knowledge-intensive tasks
- Better performance on open-domain question answering
- More interpretable with source citations

## Related Work

- [[Learning LLMs]]
- [[Embeddings]]
- [[Vector Databases]]

## Questions

- How to balance retrieval relevance vs. diversity?
- What's the optimal number of documents to retrieve?
- How to handle contradictory information in retrieved documents?

## References

- Lewis et al., "Retrieval-Augmented Generation for Knowledge-Intensive NLP Tasks"
- [[Build a Large Language Model]] - Chapter on RAG implementations
```

## When to use me

- User asks to "create research note"
- User wants to "summarise a paper"
- User says "take notes on {topic}"
- User provides paper title or research topic
- User wants to document technical concepts

## What NOT to do

- ❌ Don't create in wrong folder (must be `Atlas/Papers/`)
- ❌ Don't use American English spelling
- ❌ Don't skip the frontmatter
- ❌ Don't create duplicate notes (search first)
- ❌ Don't omit source citations when provided
