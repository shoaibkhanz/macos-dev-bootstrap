---
name: blog-draft
description: Create technical blog post drafts with proper structure, SEO, and British English for ML engineering topics
---

## What I do

1. Create blog draft in `~/code/projects/obsidian/rememberme/Efforts/Writing/` folder
2. Structure with: introduction, main sections, conclusion
3. Use British English spelling and phrasing throughout
4. Add SEO-friendly frontmatter with metadata
5. Include relevant tags from existing vault
6. Link to related notes using `[[wiki-links]]`
7. Set status as "draft" for editing workflow

## Template Structure

```markdown
---
type: Blog
title: {Title}
date: '{YYYY-MM-DD}'
tags: [blog, {topic-tags}]
description: {Brief SEO summary - under 160 characters}
status: draft
---

# {Title}

## Introduction

{Hook that draws reader in - why this topic matters}

{Context and what the post will cover}

## {Main Section 1}

{Content with examples, code snippets if technical}

## {Main Section 2}

{Continue building on concepts}

## {Main Section 3 - if needed}

{Advanced topics or practical applications}

## Conclusion

{Summary of key takeaways}

{Call to action or next steps for readers}

---

**Related**: [[Related Topic 1]] | [[Related Topic 2]]  
**Tags**: #{tag1} #{tag2} #{tag3}
```

## Filename Conventions

Use descriptive, SEO-friendly filenames:
- Format: `{Title}.md` with Title Case
- Examples: 
  - `Fine-tuning LLMs with LoRA.md`
  - `Building Production RAG Systems.md`
  - `Understanding Transformer Attention.md`
- Replace special characters with hyphens or spaces
- Keep filename under 60 characters when possible

## Tag Suggestions

Suggest relevant tags based on content:

**ML/AI Topics**:
- blog, ML, AI, LLM, transformers
- fine-tuning, RAG, embeddings
- NLP, computer-vision
- deep-learning, machine-learning
- tutorial, guide, how-to

**Technical Level**:
- beginner, intermediate, advanced
- practical, theory, implementation

**Format**:
- code-example, walkthrough, explanation

## SEO Description Guidelines

Create compelling descriptions (under 160 characters):
- Start with action words: "Learn how to...", "Discover...", "Master..."
- Include key topic/keyword
- Hint at value: "with practical examples", "step-by-step guide"
- British English spelling

Examples:
- "Learn how to fine-tune LLMs using LoRA with practical examples and code snippets."
- "Discover the inner workings of transformer attention mechanisms explained simply."
- "Build production-ready RAG systems with this comprehensive implementation guide."

## British English Requirements

All blog content must use British English:

**Spelling**:
- -ise endings: optimise, realise, analyse, organise, specialise
- -our: behaviour, colour, favour, labour
- -re: centre, metre, theatre, litre
- -ence: defence, licence (noun)
- -ll-: travelling, modelling, labelled, cancelled
- programme (for events/processes), program (for software code)

**Vocabulary**:
- "whilst" (formal writing), "amongst"
- "towards" (not "toward")
- "learnt" (past tense of learn)

**Tone**:
- Professional yet approachable
- Clear and accessible for ML engineers
- Authoritative without being pompous
- Encourage learning and experimentation

## Content Structure Tips

**Introduction (2-3 paragraphs)**:
- Hook with relatable problem or interesting fact
- Establish why topic matters
- Preview what will be covered

**Main Sections (2-4 sections)**:
- Use descriptive headings
- Break down complex concepts
- Include code examples with syntax highlighting
- Add visual descriptions (diagrams, architecture)
- Use bullet points for clarity

**Conclusion (1-2 paragraphs)**:
- Summarise key points (3-5 takeaways)
- Suggest next steps or further reading
- Encourage engagement (comments, questions)

## Code Examples

When including code, use proper markdown syntax:

```python
# Example: Fine-tuning with LoRA
from peft import LoraConfig, get_peft_model

# Configure LoRA parameters
lora_config = LoraConfig(
    r=16,  # Rank
    lora_alpha=32,
    target_modules=["q_proj", "v_proj"],
    lora_dropout=0.1,
)

# Apply LoRA to model
model = get_peft_model(base_model, lora_config)
```

## Linking to Vault Notes

Link to relevant notes in the vault:
- Related learning plans: `[[Learning LLMs]]`
- Related books: `[[Build a Large Language Model]]`
- Related concepts: `[[Transformers]]`, `[[RAG]]`, `[[Attention]]`
- Related people: `[[Author Name]]` if mentioned

## Examples

### Example 1: Technical Tutorial

**User**: "Create blog post about fine-tuning LLMs with LoRA"

**Output**: `Efforts/Writing/Fine-tuning LLMs with LoRA.md`

```markdown
---
type: Blog
title: Fine-tuning LLMs with LoRA
date: '2025-12-31'
tags: [blog, ML, LLM, fine-tuning, LoRA, tutorial]
description: Learn how to efficiently fine-tune large language models using LoRA with practical code examples.
status: draft
---

# Fine-tuning LLMs with LoRA

## Introduction

Fine-tuning large language models has traditionally required substantial computational resources and time. However, Parameter-Efficient Fine-Tuning (PEFT) methods like LoRA (Low-Rank Adaptation) have revolutionised this process, making it accessible to ML engineers working with limited resources.

In this guide, we'll explore how LoRA works, why it's effective, and how to implement it for your own projects.

## What is LoRA?

LoRA introduces trainable rank decomposition matrices into each layer of the transformer architecture whilst keeping the original model weights frozen. This approach dramatically reduces the number of trainable parameters—often by 90% or more—whilst maintaining comparable performance to full fine-tuning.

The key insight: model updates during fine-tuning often have low "intrinsic rank", meaning we can represent them with far fewer parameters than the full weight matrices.

## How LoRA Works

LoRA modifies the weight update process:
- Original: W' = W + ΔW
- LoRA: W' = W + BA (where B and A are low-rank matrices)

By setting the rank r << d (model dimension), we significantly reduce parameters whilst capturing the essential adaptation.

## Implementation Guide

Here's how to implement LoRA using the PEFT library:

```python
from transformers import AutoModelForCausalLM
from peft import LoraConfig, get_peft_model, TaskType

# Load base model
model = AutoModelForCausalLM.from_pretrained("meta-llama/Llama-2-7b-hf")

# Configure LoRA
lora_config = LoraConfig(
    task_type=TaskType.CAUSAL_LM,
    r=16,  # Rank - balance between efficiency and performance
    lora_alpha=32,  # Scaling factor
    target_modules=["q_proj", "k_proj", "v_proj", "o_proj"],
    lora_dropout=0.1,
    bias="none",
)

# Apply LoRA
model = get_peft_model(model, lora_config)

# Check trainable parameters
model.print_trainable_parameters()
# Output: trainable params: 4.2M || all params: 6.7B || trainable%: 0.06%
```

## Best Practices

When fine-tuning with LoRA:

- **Start with r=8-16**: Higher ranks offer more capacity but require more memory
- **Target attention layers**: q_proj, k_proj, v_proj, o_proj are most effective
- **Experiment with alpha**: Common ratio is alpha = 2 × r
- **Monitor overfitting**: LoRA's reduced capacity can act as regularisation
- **Save adapters separately**: Store only the small LoRA weights, not the full model

## Conclusion

LoRA has democratised LLM fine-tuning, enabling efficient adaptation with minimal resources. By understanding the rank decomposition principle and following best practices, you can fine-tune even the largest models on consumer hardware.

The key takeaways:
- LoRA reduces trainable parameters by 90%+ whilst maintaining performance
- Focus on attention layers for best results
- Start with conservative rank values and experiment
- Monitor your metrics to find the optimal configuration

Implementing LoRA in your next fine-tuning project will demonstrate these efficiency gains in practice.

---

**Related**: [[Learning LLMs]] | [[Build a Large Language Model]] | [[PEFT]]  
**Tags**: #ML #LLM #fine-tuning #LoRA #tutorial
```

### Example 2: Conceptual Explanation

**User**: "Write blog explaining transformer attention"

**Output**: `Efforts/Writing/Understanding Transformer Attention.md`

```markdown
---
type: Blog
title: Understanding Transformer Attention
date: '2025-12-31'
tags: [blog, ML, transformers, attention, NLP, explanation]
description: Discover how transformer attention mechanisms work, explained with clear examples and visualisations.
status: draft
---

# Understanding Transformer Attention

## Introduction

The attention mechanism lies at the heart of modern NLP. Since the landmark "Attention Is All You Need" paper introduced transformers in 2017, attention has become the foundational building block for models from BERT to GPT to Claude.

But what exactly is attention, and why is it so powerful? Let's demystify this crucial concept.

## The Core Idea

At its essence, attention allows a model to focus on relevant parts of the input when processing each element. Instead of treating all input tokens equally, the model learns which tokens deserve more "attention" for the current context.

Think of it like reading a sentence: when you process the word "it", you naturally look back to determine what "it" refers to. Attention mechanisms formalise this intuitive process.

## The Mechanism: Queries, Keys, and Values

Attention operates through three learned transformations:

- **Query (Q)**: What am I looking for?
- **Key (K)**: What do I contain?
- **Value (V)**: What information do I carry?

For each token, the model computes attention scores by comparing its query with all keys, then uses these scores to create a weighted sum of values.

The mathematics:
```
Attention(Q, K, V) = softmax(QK^T / √d_k) V
```

## Why It Works

Attention's power comes from several properties:

1. **Parallelisable**: Unlike RNNs, all positions computed simultaneously
2. **Long-range dependencies**: Direct connections between distant tokens
3. **Learnable focus**: Model learns what to attend to through training
4. **Interpretable**: Attention weights show what the model focuses on

## Multi-Head Attention

Transformers don't use just one attention mechanism—they use multiple "heads" operating in parallel. Each head can specialise in different types of relationships:
- Head 1: Grammatical dependencies
- Head 2: Semantic relationships
- Head 3: Positional patterns

This diversity allows richer representations whilst maintaining efficiency.

## Conclusion

Understanding attention is key to working with modern language models. The elegant query-key-value framework enables models to dynamically focus on relevant context, making transformers remarkably effective at language tasks.

Key insights:
- Attention creates weighted connections between all tokens
- Q, K, V transformations enable flexible, learnable relationships
- Multi-head attention captures diverse relationship types
- Parallelisation makes transformers scalable and efficient

This foundation provides the necessary understanding to explore advanced architectures and fine-tuning strategies.

---

**Related**: [[Attention Is All You Need]] | [[Transformers]] | [[Learning LLMs]]  
**Tags**: #transformers #attention #NLP #explanation #ML
```

## When to use me

- User asks to "create blog post"
- User says "write blog about {topic}"
- User wants to "draft article"
- User says "start blog on {subject}"
- User requests "blog draft about {topic}"

## What NOT to do

- ❌ Don't use American English spelling
- ❌ Don't create in wrong folder (must be `Efforts/Writing/`)
- ❌ Don't skip frontmatter or SEO description
- ❌ Don't exceed 160 characters for description
- ❌ Don't create duplicate blog posts (search first)
- ❌ Don't use overly technical jargon without explanation
