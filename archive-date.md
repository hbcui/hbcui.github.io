---
title: Archive/归档
layout: page
permalink: /archive-date/
---

<p><a href="/archive-category/">[Sort by Category]</a></p>

<p>Below are all posts sorted by date (newest first, descending).</p>

<ul>
{%- assign posts = site.posts | sort: "date" | reverse -%}
{%- for post in posts -%}
<li>
{{ post.date | date: "%Y-%m-%d" }} -
<a href="{{ post.url | relative_url }}">{{ post.title }}</a>
</li>
{%- endfor -%}
</ul> 