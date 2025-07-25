---
title: Archive/归档
layout: page
permalink: /archive-date/
---

<p><a href="/archive-category/">[Sort by Category/按类排列]</a></p>

<p>Below are all posts sorted by date (newest first, descending).<br/>
所有文章按日期排列（最新的在前面，降序）。</p>

<ul>
{%- assign posts = site.posts | sort: "date" | reverse -%}
{%- for post in posts -%}
<li>
{{ post.date | date: "%Y-%m-%d" }} -
<a href="{{ post.url | relative_url }}">{{ post.title }}</a>
</li>
{%- endfor -%}
</ul> 