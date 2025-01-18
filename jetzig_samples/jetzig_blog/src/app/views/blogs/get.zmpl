<div>
  <h1>{{$.blog.title}}</h1>

  <div class="content">
    {{zmpl.fmt.raw(zmpl.get("markdown"))}}
  </div>

</div>
<br/>
<a href="/blogs">Back</a>