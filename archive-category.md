---
title: Archive/归档
layout: page
permalink: /archive-category/
---

<p><a href="/archive-date/">[Sort by Date/按日排列]</a></p>

{%- assign posts = site.posts | sort: "date" | reverse -%}
{%- assign categories = "" | split: "" -%}
{%- for post in posts -%}
{%- for cat in post.categories -%}
{%- unless categories contains cat -%}
{%- assign categories = categories | push: cat -%}
{%- endunless -%}
{%- endfor -%}
{%- endfor -%}
{%- assign categories = categories | sort -%}
{%- for cat in categories -%}
<h2>{{ cat }}</h2>
<ul>
{%- for post in posts -%}
{%- if post.categories contains cat -%}
<li>
{{ post.date | date: "%b %Y" }} -
<a href="{{ post.url | relative_url }}">{{ post.title }}</a>
{%- if post.categories.size > 1 -%}
<span style="font-size:0.9em;color:#888;">({{ post.categories | join: ' / ' }})</span>
{%- endif -%}
</li>
{%- endif -%}
{%- endfor -%}
</ul>
{%- endfor -%} 