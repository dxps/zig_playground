<div>
  <span>The list of articles</span>
  <ul>
    @for ($.blogs) |blog| {
        <li>
            <a href="/blogs/{{blog.id}}">{{blog.title}}</a>
        </li>
    }
  </ul>
  
</div>
<br/>
<div>
<a href="/blogs/new">New</a>
</div>