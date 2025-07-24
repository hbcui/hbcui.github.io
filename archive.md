---
title: 归档
layout: page
permalink: /archive/
---

<ul>
  {%- assign posts = site.posts | sort: 'date' | reverse -%}
  {%- for post in posts -%}
    <li>
      <span>{{ post.date | date: '%Y-%m-%d' }}</span>
      <a href="{{ post.url | relative_url }}">{{ post.title }}</a>
    </li>
  {%- endfor -%}
</ul> 