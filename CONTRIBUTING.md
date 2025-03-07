# Contributing

## Code

## Talks
Would you like to contribute a talk to the Princeton Julia User Group? That's excellent! We are extremely grateful for your participation. This document will guide you through the process of adding a talk/post to our website.

> [!NOTE]
> Our website is created with [Jekyll](https://jekyllrb.com/). If you want to preview changes locally (or if you want to contribute to the website beyond adding a post), you'll need to learn how to work with Jekyll. Don't worry—it's easy! There are a million resources for learning Jekyll, including Jekyll's own excellent documentation, and someone on Reddit probably knows the answer to your question.

There are three talk formats you can publish to the website:

1. Markdown
2. Pluto
3. HTML

Let's take a look at how each of the options works.

### Markdown
One option is to write up your talk in Markdown. This is the simplest option. The main downside is that Markdown code blocks are non-interactive, which means readers need to do a lot of copy-pasting if the talk has a "follow-along" design.

#### Step 1: Create a Markdown file
Write up your talk in Markdown file, e.g., `plotting-in-julia.md`.

#### Step 2: Create a feature branch
Create a new feature branch off of `gh-pages`. Use the title of your talk as the branch name, e.g., `git checkout -b plotting-with-julia`.

#### Step 3: Create a post
Create a new file, e.g. `_posts/YYYY-MM-DD-plotting-in-julia.md`, where `YYYY-MM-DD` is the date of your presentation. Paste the following at the top of the new file:
```markdown
---
layout: post
title:  Plotting in Julia
date:   YYYY-MM-DD HH:MM:SS -0500
categories: meetings talks
preview: false
---
```

> [!NOTE]
> A website administrator may have create this post file for you already.

Now all you need to do finish the post is copy-paste the body of your Markdown file below the header. To create a preview to display on the homepage, simply add `<!--more-->` below the preview text.

#### Step 4: Create a PR
Once you're happy with the post, go ahead and open a pull request to merge into `gh-pages`. An admin will review the post, make formatting changes (if necessary), and then publish your work (and thank you profusely)!

### Pluto
Another option is to create a [Pluto](https://plutojl.org/) notebook. Pluto notebooks are nice because users can interact with them. Unfortunately, our Jekyll website doesn't support interaction, so we either have to host static notebook exports or publish notebooks to a separate website.

### HTML
Finally, we can host HTML documents. For example, you can convert a slide presentation to HTML. The process for contributing an HTML document is exactly the same as that of contributing a static export of a Pluto notebook.