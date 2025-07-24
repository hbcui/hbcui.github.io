---
title: Archive
layout: page
permalink: /archive/
---

{%- assign sort = page.url | split: 'sort=' | last -%}
{%- assign by_category = sort == 'category' -%}

<p>
  <a href="/archive/">Sort by Date</a> | 
  <a href="/archive/?sort=category">Sort by Category</a>
</p>

{%- if by_category -%}
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
{%- else -%}
  {%- assign posts = site.posts | sort: "date" | reverse -%}
  <ul>
    {%- for post in posts -%}
      <li>
        {{ post.date | date: "%Y-%m-%d" }} -
        <a href="{{ post.url | relative_url }}">{{ post.title }}</a>
      </li>
    {%- endfor -%}
  </ul>
{%- endif -%} 