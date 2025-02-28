<html>
  <head>
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>jetzig-sample</title>
    <script src="https://cdn.tailwindcss.com"></script>
    <link rel="stylesheet" href="/styles.css" />
  </head>

  <body>
    <div class="flex h-screen justify-center items-center text-center pt-10 m-auto">
      <!-- If present, renders the `message_param` response data value, add `?message=hello` to the
           URL to see the output: -->
      <h2 class="param text-3xl text-[#f7931e]">{{.message_param}}</h2>

      <!-- Renders `src/app/views/root/_content.zmpl`, passing in the `welcome_message` field from template data. -->
      <div>
        @partial root/content(message: .welcome_message)
      </div>
    </div>
  </body>
</html>
